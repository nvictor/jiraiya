//
//  StoryCard.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

struct StoryCard: View {
    @EnvironmentObject private var outcomeManager: OutcomeManager
    @AppStorage("jiraBaseURL") private var jiraBaseURL: String = ""
    let story: Story

    private var storyURL: URL? {
        guard !jiraBaseURL.isEmpty else { return nil }
        return URL(string: "\(jiraBaseURL)/browse/\(story.id)")
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                Text(
                    "Completed: \(story.completedAt.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.caption)
                .foregroundColor(.secondary)
                Text("Outcome: \(story.outcome)")
                    .font(.caption)
                    .foregroundColor(outcomeManager.color(for: story.outcome))
                if let url = storyURL {
                    Link("\(url.absoluteString)", destination: url)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text(story.title)
                .font(.headline)
        }
    }
}
