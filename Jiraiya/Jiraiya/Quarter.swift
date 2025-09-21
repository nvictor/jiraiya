//
//  Quarter.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import Foundation

struct Quarter: Identifiable, Hashable, StoryCollection {
    var id: String { name }
    let name: String
    let epics: [Epic]
    let year: Int

    var stories: [Story] {
        epics.flatMap { $0.stories }
    }

    
    func totalEpics() -> Int {
        epics.count
    }
    
    func totalStories() -> Int {
        epics.reduce(0) { $0 + $1.stories.count }
    }
}
