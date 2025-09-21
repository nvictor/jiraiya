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
    @AppStorage("jiraProject") private var jiraProject: String = ""
    @AppStorage("jiraStartDate") private var jiraStartDate: String = "2025-01-01"

    @State private var isSyncing = false
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
                TextField("Project", text: $jiraProject)
                DatePicker("Start Date", selection: dateBinding, displayedComponents: .date)
                Button(action: {
                    NotificationCenter.default.post(name: .navigateToRoot, object: nil)
                    Task {
                        await syncJira()
                    }
                }) {
                    HStack(spacing: 8) {
                        if isSyncing {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Connect & Sync")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(
                    isSyncing || jiraBaseURL.isEmpty || jiraEmail.isEmpty || jiraApiToken.isEmpty)
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
        .alert("Are you sure you want to reset the database?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                Task {
                    await resetDatabase()
                }
            }
        }
    }

    private var dateBinding: Binding<Date> {
        Binding<Date>(
            get: {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.date(from: jiraStartDate) ?? Date()
            },
            set: {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                jiraStartDate = formatter.string(from: $0)
            }
        )
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
        LogService.shared.log("Starting JIRA sync... (baseURL=\(jiraBaseURL))", type: .info)
        do {
            try await jiraService.sync()
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
        }
        isSyncing = false
    }
}
