//
//  StoryCard.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

struct StoryCard: View {
    @EnvironmentObject private var outcomeManager: OutcomeManager
    let story: Story

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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text(story.title)
                .font(.headline)
        }
    }
}
