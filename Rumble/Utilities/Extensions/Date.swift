//
//  Date.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/8/23.
//

import Foundation

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow: Date { return Date().dayAfter }
    var dayBefore: Date {
        // swiftlint:disable:next force_unwrapping
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        // swiftlint:disable:next force_unwrapping
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        // swiftlint:disable:next force_unwrapping
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}
