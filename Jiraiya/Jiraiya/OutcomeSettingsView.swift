//
//  OutcomeSettingsView.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/20/25.
//

import SwiftUI

struct OutcomeSettingsView: View {
    @ObservedObject var outcomeManager: OutcomeManager

    @State private var reclassifyProgress: Double? = nil

    var body: some View {
        Section {
            List {
                ForEach($outcomeManager.outcomes) { $outcome in
                    HStack {
                        Picker("Color", selection: $outcome.color) {
                            ForEach(PredefinedColor.allCases) { color in
                                Text("\u{25CF}")    // ● bullet
                                    .foregroundColor(color.color)
                                    .font(.system(size: 16))
                                    .tag(color.rawValue)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(MenuPickerStyle())

                        TextField("Outcome Name", text: $outcome.name)

                        // Binding to transform the keywords array to a comma-separated string
                        TextField(
                            "Keywords",
                            text: Binding(
                                get: { outcome.keywords.joined(separator: ", ") },
                                set: {
                                    outcome.keywords =
                                        $0
                                        .split(separator: ",")
                                        .map { $0.trimmingCharacters(in: .whitespaces) }
                                        .filter { !$0.isEmpty }
                                }
                            ))
                    }
                }
                .onDelete(perform: outcomeManager.deleteOutcome)
            }

            if let progress = reclassifyProgress, progress < 1.0 {
                VStack {
                    ProgressView(value: progress)
                    Text("Reclassifying... \(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            } else if reclassifyProgress == 1.0 {
                Text("Reclassification complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            HStack(spacing: 8) {
                Text("Outcomes")
                if outcomeManager.isDirty {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .help("Unsaved changes")
                }
                Spacer()
                HStack(spacing: 8) {
                    Button(action: { outcomeManager.addOutcome() }) {
                        Image(systemName: "plus")
                    }
                    .help("Add Outcome")
                    Button(action: {
                        outcomeManager.commit()
                        Task {
                            await OutcomeReclassifier.reclassifyAll(outcomeManager: outcomeManager)
                        }
                    }) {
                        Image(systemName: "checkmark")
                    }
                    .help("Update Outcomes")
                    .disabled(!outcomeManager.isDirty)
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .reclassifyProgress).receive(on: RunLoop.main)
        ) { note in
            if let progress = note.userInfo?["progress"] as? Double {
                reclassifyProgress = progress
                if progress >= 1.0 {
                    // Briefly show completion then clear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        reclassifyProgress = nil
                    }
                }
            }
        }
    }
}
