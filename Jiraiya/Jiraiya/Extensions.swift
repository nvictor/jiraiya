//
//  Extensions.swift
//  Jiraiya
//
//  Created by Victor Noagbodji on 9/17/25.
//

import Foundation

extension Calendar {
    /// Fiscal year starts in February on the first Monday
    func fiscalYearStart(for year: Int) -> Date {
        let startComponents = DateComponents(year: year, month: 2, day: 1)
        let febStart = self.date(from: startComponents)!

        let weekday = component(.weekday, from: febStart)
        let offset = (9 - weekday) % 7
        return date(byAdding: .day, value: offset, to: febStart)!
    }

    func fiscalQuarter(for date: Date) -> Int {
        let year = component(.year, from: date)
        let start = fiscalYearStart(for: year)
        guard date >= start else { return 4 }    // belongs to previous fiscal year

        let diff = dateComponents([.month], from: start, to: date).month ?? 0
        return (diff / 3) + 1
    }

    func fiscalMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }

    func monthName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    func fiscalYear(for date: Date) -> Int {
        let year = component(.year, from: date)
        let startOfFiscalYear = fiscalYearStart(for: year)
        if date < startOfFiscalYear {
            return year - 1
        }
        return year
    }
}

extension Notification.Name {
    static let databaseDidReset = Notification.Name("databaseDidReset")
    static let reclassifyProgress = Notification.Name("reclassifyProgress")
    static let navigateToRoot = Notification.Name("navigateToRoot")
}
