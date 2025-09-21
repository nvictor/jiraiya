//
//  OutcomeManager.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/20/25.
//

import Foundation
import SwiftUI

class OutcomeManager: ObservableObject {
    @AppStorage("outcomes") private var outcomesData: Data = Data()

    @Published var outcomes: [Outcome] {
        didSet {
            if !isInitializing {
                isDirty = true
            }
        }
    }
    @Published private(set) var isDirty: Bool = false
    private var isInitializing = true

    init() {
        self.outcomes = []    // Initialize first to satisfy the compiler
        self.outcomes = loadOutcomes()

        if self.outcomes.isEmpty {
            // Provide some default outcomes for the user to start with
            self.outcomes = [
                Outcome(
                    name: "Onboarding", keywords: ["onboarding", "signup", "welcome"],
                    color: PredefinedColor.blue.rawValue),
                Outcome(
                    name: "UX Improvement", keywords: ["ux", "ui", "design", "usability"],
                    color: PredefinedColor.orange.rawValue),
                Outcome(
                    name: "Sync", keywords: ["sync", "performance", "background"],
                    color: PredefinedColor.purple.rawValue),
            ]
        }
        isInitializing = false
        isDirty = false
    }

    func addOutcome() {
        let newOutcome = Outcome(
            name: "New Outcome", keywords: [], color: PredefinedColor.red.rawValue)
        outcomes.append(newOutcome)
    }

    func deleteOutcome(at offsets: IndexSet) {
        outcomes.remove(atOffsets: offsets)
    }

    private func loadOutcomes() -> [Outcome] {
        guard !outcomesData.isEmpty,
            let decodedOutcomes = try? JSONDecoder().decode([Outcome].self, from: outcomesData)
        else {
            return []
        }
        return decodedOutcomes
    }

    // Call this explicitly from UI when the user taps "Update Outcomes"
    func commit() {
        saveOutcomes()
        isDirty = false
    }

    private func saveOutcomes() {
        if let encodedData = try? JSONEncoder().encode(outcomes) {
            outcomesData = encodedData
        }
    }

    func outcome(for comments: [Comment]) -> Outcome {
        return outcome(forTitle: nil, comments: comments)
    }

    func outcome(forTitle title: String?, comments: [Comment]) -> Outcome {
        let commentsBlob = comments.compactMap { $0.body }
            .map { extractText(from: $0) }
            .joined(separator: " ")
        let haystack = ([title ?? "", commentsBlob].joined(separator: " ")).lowercased()

        return outcomes.first { outcome in
            outcome.keywords.contains { keyword in
                haystack.contains(keyword.lowercased())
            }
        } ?? .default
    }

    func extractText(from adf: ADFBody) -> String {
        return adf.content.map { extractText(from: $0) }.joined(separator: " ")
    }

    func extractText(from node: ADFNode) -> String {
        var text = ""
        if let nodeText = node.text {
            text += nodeText
        }
        if let content = node.content {
            for child in content {
                text += " " + extractText(from: child)
            }
        }
        return text
    }
}
