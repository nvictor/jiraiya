//
//  ColorPalette.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/20/25.
//

import Foundation
import SwiftUI

enum PredefinedColor: String, CaseIterable, Identifiable {
    case green
    case orange
    case blue
    case purple
    case red
    case gray
    case yellow
    case cyan
    case indigo

    var id: Self { self }

    var color: Color {
        switch self {
        case .green: return .green
        case .orange: return .orange
        case .blue: return .blue
        case .purple: return .purple
        case .red: return .red
        case .gray: return .gray
        case .yellow: return .yellow
        case .cyan: return .cyan
        case .indigo: return .indigo
        }
    }
}
