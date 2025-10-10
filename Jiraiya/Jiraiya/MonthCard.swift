//
//  MonthCard.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

struct MonthCard: View {
    let month: Month
    @EnvironmentObject private var outcomeManager: OutcomeManager

    var body: some View {
        GroupBox {
            OutcomeSummaryView(counts: month.outcomeCounts)
        } label: {
            Text("\(month.name) \(month.year.formatted(.number.grouping(.never))) (\(month.stories.count))")
                .font(.headline)
        }
    }
}
