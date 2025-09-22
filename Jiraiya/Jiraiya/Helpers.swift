//
//  Helpers.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

func buildQuarters(from stories: [Story]) -> [Quarter] {
    guard let firstStoryDate = stories.min(by: { $0.completedAt < $1.completedAt })?.completedAt
    else {
        return []
    }
    let cal = Calendar.current
    let fiscalYear = cal.fiscalYear(for: firstStoryDate)

    let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    // Group stories by epic
    let epicsByTitle = Dictionary(grouping: stories, by: \.epicTitle)

    let epics = epicsByTitle.map { title, stories in
        let desc: String
        if let cached = EpicDescriptionCache.shared.description(for: title) {
            desc = cached
        } else if let latest = stories.max(by: { $0.completedAt < $1.completedAt }) {
            desc =
                "Latest activity: \(mediumDateFormatter.string(from: latest.completedAt)) — \(title)"
        } else {
            desc = title
        }
        return Epic(title: title, description: desc, stories: stories)
    }

    // Group epics by quarter
    let quarterDict = Dictionary(grouping: epics) {
        // Use the latest story in the epic to determine its quarter
        guard let latestDate = $0.stories.map(\.completedAt).max() else { return 0 }
        return cal.fiscalQuarter(for: latestDate)
    }

    return (1...4)
        .map { Quarter(name: "Q\($0)", epics: quarterDict[$0] ?? [], year: fiscalYear) }
        .filter { !$0.epics.isEmpty }
}
