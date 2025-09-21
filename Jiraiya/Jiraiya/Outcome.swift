//
//  Outcome.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/20/25.
//

import Foundation
import SwiftUI

struct Outcome: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var keywords: [String]
    var color: String

    // Default outcome for stories that don't match any keywords
    static var `default`: Outcome {
        Outcome(name: "Uncategorized", keywords: [], color: PredefinedColor.gray.rawValue)
    }
}