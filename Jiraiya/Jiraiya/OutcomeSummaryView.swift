//
//  OutcomeSummaryView.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/20/25.
//

import SwiftUI

struct OutcomeSummaryView: View {
    let counts: [String: Int]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(counts.keys.sorted(), id: \.self) { key in
                if let count = counts[key], count > 0 {
                    OutcomeView(name: key, count: count)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
