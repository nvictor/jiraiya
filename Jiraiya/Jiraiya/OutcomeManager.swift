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
        let titleText = (title ?? "").lowercased()
        let commentsText = comments
            .compactMap(\.body)
            .map(extractText)
            .joined(separator: " ")
            .lowercased()

        let outcomeScores = outcomes.map { outcome -> (outcome: Outcome, score: Int) in
            let score = outcome.keywords.reduce(0) { currentScore, keyword in
                let lowercasedKeyword = keyword.lowercased()
                // Weighted keyword matching: title matches get higher priority.
                if !titleText.isEmpty && titleText.contains(lowercasedKeyword) {
                    return currentScore + 2
                } else if commentsText.contains(lowercasedKeyword) {
                    return currentScore + 1
                }
                return currentScore
            }
            return (outcome, score)
        }

        // Return the outcome with the highest score, or default if no keywords match.
        let bestMatch = outcomeScores.filter { $0.score > 0 }.max { $0.score < $1.score }
        return bestMatch?.outcome ?? .default
    }

    func extractText(from adf: ADFBody) -> String {
        adf.content.map(extractText).joined(separator: " ")
    }

    func extractText(from node: ADFNode) -> String {
        let nodeText = node.text ?? ""
        let childTexts = node.content?.map(extractText).joined(separator: " ") ?? ""
        return [nodeText, childTexts].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
