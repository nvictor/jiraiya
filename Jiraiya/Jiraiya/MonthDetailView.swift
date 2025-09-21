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

    var body: some View {
        let range = cal.range(of: .day, in: .month, for: month.date) ?? 1..<1
        let firstWeekday = cal.component(.weekday, from: month.date)
        let storiesByDay = Dictionary(grouping: month.stories) { story in
            cal.component(.day, from: story.completedAt)
        }

        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), alignment: .topLeading), count: 7),
                spacing: 8
            ) {
                // Empty slots before first day
                ForEach((0..<(firstWeekday - 1)).map { -$0 - 1 }, id: \.self) { _ in
                    Color.clear.frame(height: 40)
                }

                // Days of the month
                ForEach(range, id: \.self) { day in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(day)")
                            .font(.caption)
                        if let stories = storiesByDay[day] {
                            HStack(spacing: 2) {
                                ForEach(stories) { story in
                                    Circle()
                                        .fill(outcomeManager.color(for: story.outcome))
                                        .frame(width: 6, height: 6)
                                        .help(story.title)
                                }
                            }
                        } else {
                            Color.clear.frame(height: 6)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
                }
            }
            .padding()

            VStack {
                ForEach(month.stories) { story in
                    StoryCard(story: story)
                }
            }
            .padding()
        }
        .navigationTitle(
            "\(Calendar.current.monthName(for: month.date)) \(month.year.formatted(.number.grouping(.never)))"
        )
    }
}
