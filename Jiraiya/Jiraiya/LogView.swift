//
//  LogView.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/18/25.
//

import SwiftUI

struct LogView: View {
    @ObservedObject private var logService = LogService.shared
    @Binding var selection: Set<UUID>

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ForEach(logService.logEntries) { entry in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LogMessageView(log: entry, isSelected: selection.contains(entry.id))
                            .id(entry.id)
                    }
                    .onTapGesture {
                        if selection.contains(entry.id) {
                            selection.remove(entry.id)
                        } else {
                            selection.insert(entry.id)
                        }
                    }
                }
            }
            .padding()
            .onChange(of: logService.logEntries) { _, newEntries in
                if let lastEntry = newEntries.last {
                    proxy.scrollTo(lastEntry.id, anchor: .bottom)
                }
            }
        }
    }
}

struct ConsoleHeaderView: View {
    @ObservedObject private var logService = LogService.shared
    @Binding var selection: Set<UUID>

    var body: some View {
        HStack {
            Text("Console").font(.headline)

            Spacer()

            Button(action: copyLogs) {
                Image(systemName: "doc.on.doc")
            }
            .help("Copy Selected Logs")
            .disabled(selection.isEmpty)

            Button(action: {
                selection.removeAll()
                logService.clearLogs()
            }) {
                Image(systemName: "trash")
            }
            .help("Clear Logs")
        }
    }

    private func copyLogs() {
        let entriesToCopy = logService.logEntries.filter { selection.contains($0.id) }
        let logText =
            entriesToCopy
            .map { "[\($0.timestamp)] \($0.message)" }
            .joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logText, forType: .string)
    }
}

struct LogMessageView: View {
    let log: LogEntry
    let isSelected: Bool

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        HStack {
            Text(Self.formatter.string(from: log.timestamp)).foregroundColor(.secondary)
            log.type.symbol.foregroundColor(log.type.color)
            Text(log.message).foregroundColor(log.type.color)
        }
        .font(.system(.body, design: .monospaced))
        .background(isSelected ? Color.accentColor : Color.clear)
    }
}
