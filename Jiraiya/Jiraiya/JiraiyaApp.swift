//
//  JiraiyaApp.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

@main
struct JiraiyaApp: App {
    @StateObject private var outcomeManager = OutcomeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(outcomeManager)
                .background(BackgroundView())
        }
    }
}
