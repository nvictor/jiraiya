//
//  Helpers.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

func buildQuarters(from stories: [Story]) -> [Quarter] {
    guard let firstStoryDate = stories.min(by: { $0.completedAt < $1.completedAt })?.completedAt
    else { return [] }
    let cal = Calendar.current
    let fiscalYear = cal.fiscalYear(for: firstStoryDate)

    // Group stories by epic
    let epicsByTitle = Dictionary(grouping: stories, by: { $0.epicTitle })

    let epics = epicsByTitle.map { (title, stories) in
        let desc: String
        if let cached = EpicDescriptionCache.shared.description(for: title) {
            desc = cached
        } else if let latest = stories.sorted(by: { $0.completedAt > $1.completedAt }).first {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            desc = "Latest activity: \(formatter.string(from: latest.completedAt)) — \(title)"
        } else {
            desc = title
        }
        return Epic(title: title, description: desc, stories: stories)
    }

    // Group epics by quarter
    var quarterDict: [Int: [Epic]] = [:]
    for epic in epics {
        // Use the latest story in the epic to determine its quarter
        guard let latestDate = epic.stories.map({ $0.completedAt }).max() else { continue }
        let q = cal.fiscalQuarter(for: latestDate)
        quarterDict[q, default: []].append(epic)
    }

    var quarters: [Quarter] = []
    for q in 1...4 {
        let qEpics = quarterDict[q] ?? []
        quarters.append(Quarter(name: "Q\(q)", epics: qEpics, year: fiscalYear))
    }

    return quarters.filter { !$0.epics.isEmpty }
}
