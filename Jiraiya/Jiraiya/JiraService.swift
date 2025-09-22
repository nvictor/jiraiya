//
//  JiraService.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/18/25.
//

import Foundation
import SwiftUI

// MARK: - Codable Models for JIRA API Response

private struct JiraSearchResult: Decodable {
    let issues: [Issue]
    let nextPageToken: String?
}

private struct Issue: Decodable {
    let key: String
    let fields: IssueFields
}

private struct IssueFields: Decodable {
    let summary: String
    let resolutiondate: String?
    let updated: String?
    let parent: Parent?
    let comment: CommentConnection?
}

private struct Parent: Decodable {
    let key: String?
    let fields: ParentFields
}

private struct ParentFields: Decodable {
    let summary: String
    let issuetype: IssueType
}

private struct CommentConnection: Decodable {
    let comments: [Comment]
    let total: Int
}

private struct IssueType: Decodable {
    let name: String
}

private struct JiraSearchRequestBody: Encodable {
    let jql: String
    let maxResults: Int
    let fields: [String]
    let nextPageToken: String?
}

// MARK: - JiraError

enum JiraError: Error, LocalizedError {
    case configurationMissing
    case invalidURL
    case invalidCredentials
    case requestFailed(Error)
    case httpError(statusCode: Int, body: String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .configurationMissing:
            return
                "JIRA configuration is missing. Please set the base URL, email, and API token in Settings."
        case .invalidURL:
            return "The JIRA base URL is invalid."
        case .invalidCredentials:
            return "Could not encode JIRA credentials."
        case .requestFailed(let error):
            let nsError = error as NSError
            return
                "Network request failed: \(nsError.localizedDescription) (domain: \(nsError.domain), code: \(nsError.code))"
        case .httpError(let statusCode, let body):
            return "JIRA API returned an error: HTTP \(statusCode). Response: \(body)"
        case .decodingFailed(let error):
            return "Failed to decode JIRA API response: \(error.localizedDescription)"
        }
    }

    var underlyingError: Error? {
        switch self {
        case .requestFailed(let error): return error
        case .decodingFailed(let error): return error
        default: return nil
        }
    }
}

// MARK: - JiraService

class JiraService {
    @AppStorage("jiraBaseURL") private var jiraBaseURL: String = ""
    @AppStorage("jiraEmail") private var jiraEmail: String = ""
    @AppStorage("jiraApiToken") private var jiraApiToken: String = ""
    @AppStorage("jiraProject") private var jiraProject: String = ""
    @AppStorage("jiraStartDate") private var jiraStartDate: String = "2025-01-01"

    private let outcomeManager = OutcomeManager()

    func sync() async throws {
        // Stage 1: fetching issues
        NotificationCenter.default.post(
            name: .jiraSyncProgress, object: nil,
            userInfo: ["progress": 0.05, "message": "Fetching issues..."])
        let issues = try await fetchIssues()

        // Stage 2: processing issues to stories
        NotificationCenter.default.post(
            name: .jiraSyncProgress, object: nil,
            userInfo: ["progress": 0.35, "message": "Processing issues..."])
        let (stories, epicKeyByTitle) = try await processIssues(issues: issues)

        await LogService.shared.log("Successfully processed \(stories.count) stories.", type: .info)

        // If nothing to write, still complete
        if stories.isEmpty {
            NotificationCenter.default.post(
                name: .jiraSyncProgress, object: nil,
                userInfo: ["progress": 1.0, "message": "No stories to update."])
            return
        }

        // Stage 3: writing to database
        NotificationCenter.default.post(
            name: .jiraSyncProgress, object: nil,
            userInfo: ["progress": 0.7, "message": "Saving to database..."])
        try await DatabaseManager.shared.replaceStories(stories)

        // Stage 4: fetching epic descriptions (best-effort)
        NotificationCenter.default.post(
            name: .jiraSyncProgress, object: nil,
            userInfo: ["progress": 0.85, "message": "Fetching epic descriptions..."])
        await fetchAndCacheEpicDescriptions(epicKeyByTitle)

        // Done
        NotificationCenter.default.post(
            name: .jiraSyncProgress, object: nil,
            userInfo: ["progress": 1.0, "message": "Sync complete."])
    }

    // Extracted logic for fetching
    private func fetchIssues() async throws -> [Issue] {
        var allIssues: [Issue] = []
        var nextPageToken: String?
        let maxResults = 100

        repeat {
            var jqlParts = ["status = Done"]
            if !jiraProject.isEmpty {
                jqlParts.insert("project = \"\(jiraProject)\"", at: 0)
            }
            if !jiraStartDate.isEmpty {
                jqlParts.append("resolutiondate >= \"\(jiraStartDate)\"")
            }
            let jql = jqlParts.joined(separator: " AND ") + " order by updated DESC"
            let fields = ["summary", "updated", "resolutiondate", "parent", "comment", "issuetype"]

            let requestBody = JiraSearchRequestBody(
                jql: jql,
                maxResults: maxResults,
                fields: fields,
                nextPageToken: nextPageToken
            )

            let data = try await performAPIRequest(
                path: "/rest/api/3/search/jql",
                method: "POST",
                body: requestBody
            )

            let decoder = JSONDecoder()
            let searchResult: JiraSearchResult
            do {
                searchResult = try decoder.decode(JiraSearchResult.self, from: data)
            } catch {
                throw JiraError.decodingFailed(error)
            }

            allIssues.append(contentsOf: searchResult.issues)
            nextPageToken = searchResult.nextPageToken

        } while nextPageToken != nil

        return allIssues
    }

    // Cached formatters for performance
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackISO8601Formatter = ISO8601DateFormatter()

    // Extracted logic for processing
    private func processIssues(issues: [Issue]) async throws -> (
        stories: [Story], epicKeyByTitle: [String: String]
    ) {
        await LogService.shared.log(
            "Fetched \(issues.count) issues from Jira. Processing...", type: .info)

        var stories: [Story] = []
        var epicKeyByTitle: [String: String] = [:]
        for issue in issues {
            guard let completedAtString = issue.fields.resolutiondate ?? issue.fields.updated else {
                await LogService.shared.log(
                    "Skipping issue \(issue.key): missing resolutiondate and updated fields.",
                    type: .warning)
                continue
            }

            guard
                let completedAt = Self.iso8601Formatter.date(from: completedAtString)
                    ?? Self.fallbackISO8601Formatter.date(from: completedAtString)
            else {
                await LogService.shared.log(
                    "Skipping issue \(issue.key): failed to parse date '\(completedAtString)'.",
                    type: .warning)
                continue
            }

            let epicTitle: String
            if let parent = issue.fields.parent, parent.fields.issuetype.name == "Epic" {
                epicTitle = parent.fields.summary
                if let epicKey = parent.key {
                    epicKeyByTitle[epicTitle] = epicKey
                }
            } else {
                epicTitle = "No Epic"
            }

            let comments = try await fetchComments(for: issue.key)
            let outcome = outcomeManager.outcome(forTitle: issue.fields.summary, comments: comments)

            let story = Story(
                id: issue.key,
                title: issue.fields.summary,
                completedAt: completedAt,
                outcome: outcome.name,
                epicTitle: epicTitle
            )
            stories.append(story)
        }
        return (stories, epicKeyByTitle)
    }

    private func fetchAndCacheEpicDescriptions(_ map: [String: String]) async {
        for (title, key) in map {
            do {
                let desc = try await fetchEpicDescription(for: key)
                if !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    EpicDescriptionCache.shared.setDescription(desc, for: title)
                }
            } catch {
                // Best-effort; ignore failures per epic
                await LogService.shared.log(
                    "Failed fetching description for epic \(title): \(error.localizedDescription)",
                    type: .warning)
            }
        }
    }

    private struct IssueDescriptionResult: Decodable {
        let fields: IssueDescriptionFields
    }
    private struct IssueDescriptionFields: Decodable {
        let description: ADFBody?
    }

    private func fetchEpicDescription(for epicKey: String) async throws -> String {
        let data = try await performAPIRequest(
            path: "/rest/api/3/issue/\(epicKey)",
            method: "GET",
            queryItems: [URLQueryItem(name: "fields", value: "description")]
        )
        let decoder = JSONDecoder()
        let result = try decoder.decode(IssueDescriptionResult.self, from: data)
        return adfText(result.fields.description)
    }

    private func adfText(_ body: ADFBody?) -> String {
        guard let body else { return "" }

        func extract(_ node: ADFNode) -> String {
            let nodeText = node.text ?? ""
            let childTexts = node.content?.map(extract).joined(separator: " ") ?? ""
            return [nodeText, childTexts].filter { !$0.isEmpty }.joined(separator: " ")
        }

        return body.content.map(extract).joined(separator: " ")
    }

    func fetchComments(for issueKey: String) async throws -> [Comment] {
        var allComments: [Comment] = []
        var startAt = 0
        let maxResults = 50

        while true {
            let queryItems = [
                URLQueryItem(name: "startAt", value: "\(startAt)"),
                URLQueryItem(name: "maxResults", value: "\(maxResults)"),
            ]
            let data = try await performAPIRequest(
                path: "/rest/api/3/issue/\(issueKey)/comment",
                method: "GET",
                queryItems: queryItems
            )

            let decoder = JSONDecoder()
            let commentConnection: CommentConnection
            do {
                commentConnection = try decoder.decode(CommentConnection.self, from: data)
            } catch {
                throw JiraError.decodingFailed(error)
            }

            allComments.append(contentsOf: commentConnection.comments)

            if commentConnection.total > allComments.count {
                startAt += maxResults
            } else {
                break
            }
        }
        return allComments
    }

    private func performAPIRequest<T: Encodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: T? = nil
    ) async throws -> Data {
        guard !jiraBaseURL.isEmpty, !jiraEmail.isEmpty, !jiraApiToken.isEmpty else {
            throw JiraError.configurationMissing
        }

        guard var components = URLComponents(string: jiraBaseURL) else {
            throw JiraError.invalidURL
        }

        components.path = path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw JiraError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let credentials = "\(jiraEmail):\(jiraApiToken)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw JiraError.invalidCredentials
        }
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw JiraError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JiraError.requestFailed(
                NSError(
                    domain: "JiraService", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response from server."]))
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(decoding: data, as: UTF8.self)
            throw JiraError.httpError(statusCode: httpResponse.statusCode, body: body)
        }

        return data
    }

    // Overload for calls without a request body
    private func performAPIRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Data {
        // Create a dummy Encodable? type for the body parameter
        let dummyBody: Data? = nil
        return try await performAPIRequest(
            path: path,
            method: method,
            queryItems: queryItems,
            body: dummyBody
        )
    }
}
