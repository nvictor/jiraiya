import Foundation
import SwiftUI

enum LogType {
    case info
    case success
    case error
    case warning
}

struct LogEntry: Identifiable, Hashable, Equatable {
    let id = UUID()
    let message: String
    let type: LogType
    let timestamp: Date
}

extension LogType {
    var symbol: Image {
        switch self {
        case .info: return Image(systemName: "info.circle")
        case .success: return Image(systemName: "checkmark.circle")
        case .error: return Image(systemName: "xmark.circle")
        case .warning: return Image(systemName: "exclamationmark.circle")
        }
    }

    var color: Color {
        switch self {
        case .info: return .primary
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        }
    }
}
