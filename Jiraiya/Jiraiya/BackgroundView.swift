//
//  BackgroundView.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/21/25.
//

import SwiftUI

struct BackgroundView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear.ignoresSafeArea()
            
            Image("background")
                .resizable()
                .frame(width: 394, height: 500)
                .padding(10)
                .opacity(0.2)
        }
    }
}
