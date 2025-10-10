//
//  DatabaseManager.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/18/25.
//

import Foundation
import GRDB

class DatabaseManager {
    static let shared = DatabaseManager()

    var dbQueue: DatabaseQueue

    private init() {
        do {
            let fileManager = FileManager.default
            let dbPath =
                try fileManager
                .url(
                    for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
                    create: true
                )
                .appendingPathComponent("jiraiya.sqlite")
                .path

            dbQueue = try DatabaseQueue(path: dbPath)
            try dbQueue.write { db in
                try self.createTables(db)
            }
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    private func createTables(_ db: Database) throws {
        try db.create(table: "story", ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("title", .text).notNull()
            t.column("completedAt", .datetime).notNull()
            t.column("outcome", .text).notNull()
            t.column("epicTitle", .text).notNull()
            t.column("isResolved", .boolean).notNull()
        }
    }

    func fetchStories() throws -> [Story] {
        try dbQueue.read { db in
            try Story.fetchAll(db)
        }
    }

    func saveStories(_ stories: [Story]) async throws {
        try await dbQueue.write { db in
            for story in stories {
                try story.save(db)
            }
        }
    }

    func clearStories() async throws {
        try await dbQueue.write { db in
            _ = try Story.deleteAll(db)
        }
    }

    /// Replaces all stories in a single transaction (clear + save)
    func replaceStories(_ stories: [Story]) async throws {
        try await dbQueue.write { db in
            _ = try Story.deleteAll(db)
            for story in stories {
                try story.save(db)
            }
        }
    }

    func resetDatabase() async throws {
        try await dbQueue.write { db in
            try db.execute(sql: "DROP TABLE IF EXISTS story")
            try self.createTables(db)
        }
    }
}
