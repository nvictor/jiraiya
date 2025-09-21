//
//  MonthDetailView.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

struct MonthDetailView: View {
    @EnvironmentObject private var outcomeManager: OutcomeManager
    let month: Month
    let cal = Calendar.current

    private var storiesByDay: [Int: [Story]] {
        Dictionary(grouping: month.stories) { story in
            cal.component(.day, from: story.completedAt)
        }
    }

    private var sortedDays: [Int] {
        storiesByDay.keys.sorted()
    }

    var body: some View {
        List {
            ForEach(sortedDays, id: \.self) { day in
                Section(header: Text(dayHeader(day))) {
                    if let stories = storiesByDay[day] {
                        ForEach(stories) { story in
                            StoryCard(story: story)
                        }
                    }
                }
            }
        }
        .navigationTitle(
            "\(Calendar.current.monthName(for: month.date)) \(month.year.formatted(.number.grouping(.never)))"
        )
    }

    private func dayHeader(_ day: Int) -> String {
        let components = DateComponents(
            year: month.year, month: cal.component(.month, from: month.date), day: day)
        if let date = cal.date(from: components) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
        return "\(day)"
    }
}
