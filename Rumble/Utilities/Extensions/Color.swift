//
//  Color.swift
//  Rumble
//

import SwiftUI

extension Color {
    static func magnitudeColor(for magnitude: Double) -> Color {
        switch magnitude {
        case ..<2.0:  return Color(uiColor: .systemGray)
        case 2.0..<4.0: return Color(uiColor: .systemYellow)
        case 4.0..<5.0: return Color(uiColor: .systemOrange)
        case 5.0..<7.0: return Color(uiColor: .systemRed)
        default:      return Color(uiColor: .systemPurple)
        }
    }
}
