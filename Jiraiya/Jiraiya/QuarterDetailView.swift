//
//  QuarterDetailView.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import SwiftUI

struct QuarterDetailView: View {
    let quarter: Quarter

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible())]) {
                ForEach(quarter.epics) { epic in
                    NavigationLink(value: epic) {
                        EpicCard(epic: epic)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(quarter.name)
    }
}
