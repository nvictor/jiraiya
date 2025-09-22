//
//  StoryCollection.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/20/25.
//

import Foundation

protocol StoryCollection {
    var stories: [Story] { get }
}

extension StoryCollection {
    var outcomeCounts: [String: Int] {
        Dictionary(grouping: stories, by: \.outcome).mapValues(\.count)
    }
}
