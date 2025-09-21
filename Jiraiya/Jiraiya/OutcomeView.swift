// filepath: /Users/victor/Developer/jiraiya/Jiraiya/Jiraiya/OutcomeView.swift
import SwiftUI

struct OutcomeView: View {
    @EnvironmentObject private var outcomeManager: OutcomeManager
    let name: String
    let count: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Circle()
                .fill(outcomeManager.color(for: name))
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)
            Text("\(name) \(count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
