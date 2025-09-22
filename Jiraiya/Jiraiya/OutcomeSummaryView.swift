//
//  OutcomeSummaryView.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/20/25.
//

import SwiftUI

struct OutcomeSummaryView: View {
    let counts: [String: Int]

    private var sortedOutcomes: [(String, Int)] {
        counts
            .filter { $0.value > 0 }
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(sortedOutcomes, id: \.0) { name, count in
                OutcomeView(name: name, count: count)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
