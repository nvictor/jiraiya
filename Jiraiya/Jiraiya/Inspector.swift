//
//  Inspector.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/18/25.
//

import SwiftUI

struct Inspector: View {
    @EnvironmentObject private var outcomeManager: OutcomeManager
    @AppStorage("jiraBaseURL") private var jiraBaseURL: String = ""
    @AppStorage("jiraEmail") private var jiraEmail: String = ""
    @AppStorage("jiraApiToken") private var jiraApiToken: String = ""
    @AppStorage("jiraJQL") private var jiraJQL: String = "status = Done AND resolutiondate >= \"2025-01-01\""

    @State private var isSyncing = false
    @State private var syncProgress: Double? = nil
    @State private var syncMessage: String? = nil
    @State private var showingResetAlert = false

    private let jiraService = JiraService()

    var body: some View {
        Form {
            Section("JIRA API Details") {
                TextField("API URL", text: $jiraBaseURL)
                    .textContentType(.URL)
                TextField("Email", text: $jiraEmail)
                    .textContentType(.emailAddress)
                SecureField("API Token", text: $jiraApiToken)
                VStack(alignment: .leading) {
                    Text("JQL Query").font(.caption)
                    TextEditor(text: $jiraJQL)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 100)
                    Text(
                        "Example: project = \"MYPROJ\" AND status = Done AND resolutiondate >= \"2025-01-01\""
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                if isSyncing || (syncProgress != nil && (syncProgress ?? 0) < 1.0) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let progress = syncProgress, progress < 1.0 {
                            ProgressView(value: progress)
                            Text("\(syncMessage ?? "Syncing...") \(Int(progress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ProgressView()
                            Text(syncMessage ?? "Syncing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Button(action: {
                        NotificationCenter.default.post(name: .navigateToRoot, object: nil)
                        Task {
                            await syncJira()
                        }
                    }) {
                        Text("Connect & Sync")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(jiraBaseURL.isEmpty || jiraEmail.isEmpty || jiraApiToken.isEmpty)

                    if let progress = syncProgress, progress >= 1.0 {
                        Text("Sync complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            OutcomeSettingsView(outcomeManager: outcomeManager)

            Section("Database") {
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Text("Reset Database")
                        .frame(maxWidth: .infinity)
                }
            }

            ConsoleView()
        }
        .padding()
        .frame(minWidth: 280)
        .onReceive(
            NotificationCenter.default.publisher(for: .jiraSyncProgress).receive(on: RunLoop.main)
        ) { note in
            if let progress = note.userInfo?["progress"] as? Double {
                syncProgress = progress
            }
            if let msg = note.userInfo?["message"] as? String {
                syncMessage = msg
            }
            if let p = syncProgress, p >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    syncProgress = nil
                    syncMessage = nil
                }
            }
        }
        .alert("Are you sure you want to reset the database?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                Task {
                    await resetDatabase()
                }
            }
        }
    }

    @MainActor
    private func resetDatabase() async {
        do {
            try await DatabaseManager.shared.resetDatabase()
            LogService.shared.log("Database has been reset.", type: .success)
            NotificationCenter.default.post(name: .databaseDidReset, object: nil)
        } catch {
            LogService.shared.log(
                "Failed to reset database: \(error.localizedDescription)", type: .error)
        }
    }

    @MainActor
    private func syncJira() async {
        isSyncing = true
        syncProgress = 0.0
        LogService.shared.log("Starting JIRA sync... (baseURL=\(jiraBaseURL))", type: .info)
        do {
            try await jiraService.sync()
            NotificationCenter.default.post(name: .databaseDidReset, object: nil)
            LogService.shared.log("JIRA sync completed successfully.", type: .success)
        } catch {
            // Log the basic localized description
            LogService.shared.log("JIRA sync failed: \(error.localizedDescription)", type: .error)

            // Prefer to log the underlying NSError if JiraError wraps one
            if let jiraErr = error as? JiraError, let underlying = jiraErr.underlyingError {
                let ns = underlying as NSError
                LogService.shared.log(
                    "JIRA sync error details: domain=\(ns.domain), code=\(ns.code), userInfo=\(ns.userInfo)",
                    type: .error)
            } else {
                let ns = error as NSError
                LogService.shared.log(
                    "JIRA sync error details: domain=\(ns.domain), code=\(ns.code), userInfo=\(ns.userInfo)",
                    type: .error)
            }
            // Ensure progress is cleared on failure
            syncProgress = nil
            syncMessage = nil
        }
        isSyncing = false
    }
}
