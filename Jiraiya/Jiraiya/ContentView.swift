//
//  ContentView.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var outcomeManager: OutcomeManager
    @State private var stories: [Story] = []
    @State private var showInspector = false
    @State private var path = NavigationPath()

    private var quarters: [Quarter] {
        buildQuarters(from: stories)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                if stories.isEmpty {
                    ContentUnavailableView(
                        "No Stories", systemImage: "doc.text.magnifyingglass",
                        description: Text("Connect to JIRA and sync your stories to get started."))
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(quarters) { quarter in
                            NavigationLink(value: quarter) {
                                QuarterCard(quarter: quarter)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Quarters")
            .navigationDestination(for: Quarter.self) { quarter in
                QuarterDetailView(quarter: quarter)
            }
            .navigationDestination(for: Epic.self) { epic in
                EpicDetailView(epic: epic)
            }
            .navigationDestination(for: Month.self) { month in
                MonthDetailView(month: month)
            }
        }
        .inspector(isPresented: $showInspector) {
            Inspector()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    path = NavigationPath()
                    loadStories()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            ToolbarItem {
                Button {
                    showInspector.toggle()
                } label: {
                    Label("Settings", systemImage: "sidebar.trailing")
                }
            }
        }
        .onAppear(perform: loadStories)
        .onReceive(NotificationCenter.default.publisher(for: .databaseDidReset).receive(on: RunLoop.main)) { _ in
            loadStories()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToRoot).receive(on: RunLoop.main)) { _ in
            path = NavigationPath()
        }
    }

    private func loadStories() {
        do {
            stories = try DatabaseManager.shared.fetchStories()
        } catch {
            print("Failed to load stories from database: \(error)")
            // Consider showing an error to the user
        }
    }
}

#Preview {
    ContentView()
}
