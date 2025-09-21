//
//  Month.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import Foundation

struct Month: Identifiable, Hashable, StoryCollection {
    var id: Date { date }
    let name: String
    let stories: [Story]
    let date: Date
    let year: Int
}
