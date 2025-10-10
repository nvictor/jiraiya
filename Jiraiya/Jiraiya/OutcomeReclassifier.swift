//
//  OutcomeReclassifier.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import Foundation

enum OutcomeReclassifier {
    static func reclassifyAll(outcomeManager: OutcomeManager) async {
        let service = JiraService()
        do {
            // Fetch current stories from DB
            let stories = try DatabaseManager.shared.fetchStories()
            if stories.isEmpty { return }

            var updatedStories: [Story] = []

            for (index, story) in stories.enumerated() {
                // Fetch comments per issue and compute outcome again
                let comments = try await service.fetchComments(for: story.id)
                let outcome = outcomeManager.outcome(forTitle: story.title, comments: comments)
                let updated = Story(
                    id: story.id,
                    title: story.title,
                    completedAt: story.completedAt,
                    outcome: outcome.name,
                    epicTitle: story.epicTitle,
                    isResolved: story.isResolved
                )
                updatedStories.append(updated)

                let progress = Double(index + 1) / Double(stories.count)
                NotificationCenter.default.post(
                    name: .reclassifyProgress,
                    object: nil,
                    userInfo: ["progress": progress]
                )
            }

            // Persist updates in a single transaction
            try await DatabaseManager.shared.replaceStories(updatedStories)

            NotificationCenter.default.post(name: .databaseDidReset, object: nil)
        } catch {
            await LogService.shared.log(
                "Reclassification failed: \(error.localizedDescription)", type: .error)
        }
    }
}
