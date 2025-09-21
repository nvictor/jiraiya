//
//  Story.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import Foundation
import GRDB

struct Story: Identifiable, Hashable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    let title: String
    let completedAt: Date
    let outcome: String
    let epicTitle: String

    static var databaseTableName = "story"
}
