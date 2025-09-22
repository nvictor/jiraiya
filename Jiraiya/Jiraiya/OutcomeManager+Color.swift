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
        outcomes
            .first { $0.name == outcomeName }
            .flatMap { PredefinedColor(rawValue: $0.color) }?
            .color ?? PredefinedColor.gray.color
    }
}
