//
//  OutcomeManager+Color.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/20/25.
//

import Foundation
import SwiftUI

extension OutcomeManager {
    func color(for outcomeName: String) -> Color {
        if let outcome = outcomes.first(where: { $0.name == outcomeName }),
           let predefinedColor = PredefinedColor(rawValue: outcome.color) {
            return predefinedColor.color
        }
        return PredefinedColor.gray.color
    }
}
