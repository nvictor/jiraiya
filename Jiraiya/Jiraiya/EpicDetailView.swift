//
//  EpicDetailView.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

struct EpicDetailView: View {
    @EnvironmentObject private var outcomeManager: OutcomeManager
    let epic: Epic

    private var months: [Month] {
        let cal = Calendar.current

        return Dictionary(grouping: epic.stories) {
            cal.fiscalMonth(for: $0.completedAt)
        }
        .map { date, stories in
            Month(
                name: cal.monthName(for: date),
                stories: stories,
                date: date,
                year: cal.component(.year, from: date)
            )
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(epic.description)
                    .font(.body)
                    .padding(.bottom)

                ForEach(months) { month in
                    NavigationLink(value: month) {
                        MonthCard(month: month)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(epic.title)
    }
}
