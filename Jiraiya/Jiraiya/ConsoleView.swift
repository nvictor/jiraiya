//
//  ConsoleView.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/18/25.
//

import SwiftUI

struct ConsoleView: View {
    @State private var selection = Set<UUID>()

    var body: some View {
        Section {
            LogView(selection: $selection)
        } header: {
            ConsoleHeaderView(selection: $selection)
        }
    }
}
