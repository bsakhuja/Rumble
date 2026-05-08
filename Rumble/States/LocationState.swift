//
//  LocationState.swift
//  Rumble
//
//  Created by Brian Sakhuja on 5/5/24.
//

import Foundation
import CoreLocation

class LocationState: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    @Published var authorizationStatus: CLAuthorizationStatus?
    
    var locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:  // Location services are available.
            // Insert code here of what should happen when Location services are authorized
            locationManager.requestLocation()

        case .restricted, .denied:  // Location services currently unavailable.
            // Insert code here of what should happen when Location services are NOT authorized
            break

        case .notDetermined:        // Authorization not determined yet.
            manager.requestWhenInUseAuthorization()
            
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Insert code to handle location updates
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error.localizedDescription)")
    }
}
