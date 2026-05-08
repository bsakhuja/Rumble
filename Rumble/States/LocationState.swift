//
//  LocationState.swift
//  Rumble
//
//  Created by Brian Sakhuja on 5/5/24.
//

import Foundation
import CoreLocation
import Observation

@Observable
@MainActor
final class LocationState {
    var authorizationStatus: CLAuthorizationStatus?
    let locationManager = CLLocationManager()

    private var delegate: LocationDelegate?

    init() {
        let d = LocationDelegate(state: self)
        self.delegate = d
        locationManager.delegate = d
    }
}

private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    weak var state: LocationState?

    init(state: LocationState) {
        self.state = state
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        let state = self.state
        Task { @MainActor in
            state?.authorizationStatus = status
        }
        switch status {
        case .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
