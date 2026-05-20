//
//  SettingsState.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/21/23.
//

import Foundation
import CoreLocation
import Observation

enum SortMethod: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case none = "None"
    case locationAscending = "Location ascending (closest first)"
    case locationDescending = "Location descending (farthest first)"
    case magnitudeAscending = "Magnitude ascending (lowest first)"
    case magnitudeDescending = "Magnitude descending (largest first)"
    case timeAscending = "Time ascending (oldest first)"
    case timeDescending = "Time descending (newest first)"

    var shortName: String {
        switch self {
        case .none: return "Default"
        case .locationAscending: return "Nearest"
        case .locationDescending: return "Farthest"
        case .magnitudeAscending: return "Smallest"
        case .magnitudeDescending: return "Largest"
        case .timeAscending: return "Oldest"
        case .timeDescending: return "Newest"
        }
    }
}

@Observable
@MainActor
final class SettingsState {
    var magnitudeLower: Int = UserDefaults.standard.object(forKey: "magnitudeLower") as? Int ?? 0 {
        didSet { UserDefaults.standard.set(magnitudeLower, forKey: "magnitudeLower") }
    }
    var magnitudeUpper: Int = UserDefaults.standard.object(forKey: "magnitudeUpper") as? Int ?? 10 {
        didSet { UserDefaults.standard.set(magnitudeUpper, forKey: "magnitudeUpper") }
    }
    private var sortMethodRaw: String = UserDefaults.standard.string(forKey: "sortMethodRaw") ?? SortMethod.none.rawValue {
        didSet { UserDefaults.standard.set(sortMethodRaw, forKey: "sortMethodRaw") }
    }
    var dateRangeDays: Int = UserDefaults.standard.object(forKey: "dateRangeDays") as? Int ?? 1 {
        didSet { UserDefaults.standard.set(dateRangeDays, forKey: "dateRangeDays") }
    }
    var notificationMinMagnitude: Double = UserDefaults.standard.object(forKey: "notificationMinMagnitude") as? Double ?? 5.0 {
        didSet { UserDefaults.standard.set(notificationMinMagnitude, forKey: "notificationMinMagnitude") }
    }
    var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled") {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    var isPresented: Bool = false

    var sortMethod: SortMethod {
        get { SortMethod(rawValue: sortMethodRaw) ?? .none }
        set { sortMethodRaw = newValue.rawValue }
    }

    var dateStart: Date {
        Calendar.current.date(byAdding: .day, value: -dateRangeDays, to: Date.now) ?? Date.now
    }

    var dateEnd: Date { Date.now }

    var locationState = LocationState()

    var userLocation: CLLocation? {
        locationState.locationManager.location
    }
}
