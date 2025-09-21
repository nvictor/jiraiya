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
    let total: Int
    let startAt: Int
    let maxResults: Int
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

    private let outcomeManager = OutcomeManager()

    func sync() async throws {
        let issues = try await fetchIssues()
        let (stories, epicKeyByTitle) = try await processIssues(issues: issues)

        await LogService.shared.log("Successfully processed \(stories.count) stories.", type: .info)

        if stories.isEmpty { return }

        try await DatabaseManager.shared.replaceStories(stories)
        await fetchAndCacheEpicDescriptions(epicKeyByTitle)
    }

    // Extracted logic for fetching
    private func fetchIssues() async throws -> [Issue] {
        var allIssues: [Issue] = []
        var startAt = 0
        let maxResults = 100

        while true {
            var jqlParts = ["statusCategory = Done"]
            if !jiraProject.isEmpty {
                jqlParts.insert("project = \"\(jiraProject)\"", at: 0)
            }
            let jql = jqlParts.joined(separator: " AND ") + " order by updated DESC"

            let fields = ["summary", "updated", "resolutiondate", "parent", "comment", "issuetype"]
            let queryItems = [
                URLQueryItem(name: "jql", value: jql),
                URLQueryItem(name: "fields", value: fields.joined(separator: ",")),
                URLQueryItem(name: "maxResults", value: "\(maxResults)"),
                URLQueryItem(name: "startAt", value: "\(startAt)"),
            ]
            let data = try await performAPIRequest(
                path: "/rest/api/3/search", queryItems: queryItems)

            let decoder = JSONDecoder()
            let searchResult: JiraSearchResult
            do {
                searchResult = try decoder.decode(JiraSearchResult.self, from: data)
            } catch {
                throw JiraError.decodingFailed(error)
            }

            allIssues.append(contentsOf: searchResult.issues)

            if searchResult.total > allIssues.count {
                startAt += searchResult.maxResults
            } else {
                break
            }
        }
        return allIssues
    }

    // Extracted logic for processing
    private func processIssues(issues: [Issue]) async throws -> (stories: [Story], epicKeyByTitle: [String: String]) {
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

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            guard
                let completedAt = formatter.date(from: completedAtString)
                    ?? ISO8601DateFormatter().date(from: completedAtString)
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
            queryItems: [URLQueryItem(name: "fields", value: "description")]
        )
        let decoder = JSONDecoder()
        let result = try decoder.decode(IssueDescriptionResult.self, from: data)
        return adfText(result.fields.description)
    }

    private func adfText(_ body: ADFBody?) -> String {
        guard let body else { return "" }
        func extract(_ node: ADFNode) -> String {
            var t = node.text ?? ""
            if let children = node.content {
                for c in children { t += (t.isEmpty ? "" : " ") + extract(c) }
            }
            return t
        }
        return body.content.map { extract($0) }.joined(separator: " ")
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
                path: "/rest/api/3/issue/\(issueKey)/comment", queryItems: queryItems)

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

    private func performAPIRequest(path: String, queryItems: [URLQueryItem]) async throws -> Data {
        guard !jiraBaseURL.isEmpty, !jiraEmail.isEmpty, !jiraApiToken.isEmpty else {
            throw JiraError.configurationMissing
        }

        guard var components = URLComponents(string: jiraBaseURL) else {
            throw JiraError.invalidURL
        }

        components.path = path
        components.queryItems = queryItems

        guard let url = components.url else {
            throw JiraError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

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
}
