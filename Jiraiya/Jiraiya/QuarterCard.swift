//
//  QuarterCard.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

struct QuarterCard: View {
    let quarter: Quarter
    @EnvironmentObject private var outcomeManager: OutcomeManager

    var body: some View {
        GroupBox {
            OutcomeSummaryView(counts: quarter.outcomeCounts)
        } label: {
            Text(quarter.name)
                .font(.headline)
        }
    }
}
