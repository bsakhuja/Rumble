//
//  Round.swift
//  Rumble
//
//  Created by Brian Sakhuja on 1/11/24.
//

import Foundation

// Specify the decimal place to round to using an enum
public enum RoundingPrecision {
    case ones
    case tenths
    case hundredths
}

// Round to the specific decimal place
public func preciseRound(
    _ value: Double,
    precision: RoundingPrecision = .ones) -> String {
    switch precision {
    case .ones:
        return String(round(value))
    case .tenths:
        return String(round(value * 10) / 10.0)
    case .hundredths:
        return String(round(value * 100) / 100.0)
    }
}
