//
//  Epic.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import Foundation

struct Epic: Identifiable, Hashable, StoryCollection {
    var id: String { title }
    let title: String
    let description: String
    let stories: [Story]
}
