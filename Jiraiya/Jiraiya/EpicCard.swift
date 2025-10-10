//
//  EpicCard.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

struct EpicCard: View {
    let epic: Epic
    @EnvironmentObject private var outcomeManager: OutcomeManager

    var body: some View {
        GroupBox {
            OutcomeSummaryView(counts: epic.outcomeCounts)
        } label: {
            Text("\(epic.title) (\(epic.stories.count))")
                .font(.headline)
        }
    }
}
