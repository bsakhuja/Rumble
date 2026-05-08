//
//  EarthquakeGeometry.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/8/23.
//

import Foundation
import MapKit
import _MapKit_SwiftUI

struct EarthquakeGeometry: Identifiable, Decodable {
    var id: String { coordinates.description }
    let type: String
    let coordinates: [Double]
    
    var coordinate2D: CLLocationCoordinate2D {
        let lat = CLLocationDegrees(coordinates[1])
        let long = CLLocationDegrees(coordinates[0])
        
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    var locationName: String?
    
    var clLocation: CLLocation {
        let lat = CLLocationDegrees(coordinates[1])
        let long = CLLocationDegrees(coordinates[0])
        
        return CLLocation(latitude: lat, longitude: long)
    }
    
    var mapCameraPosition: MapCameraPosition {
        .camera(MapCamera(centerCoordinate: coordinate2D, distance: 100000))
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawType = try? values.decode(String.self, forKey: .type)
        let rawCoordinates = try? values.decode([Double].self, forKey: .coordinates)
        
        guard let type = rawType,
              let coordinates = rawCoordinates
        else {
            print("error parsing EarthquakeGeometry")
            throw QuakeError.missingData
        }
        
        self.type = type
        self.coordinates = coordinates
//        self.locationName = getLocality()
    }
    
    func getLocality() -> String? {
        let geocoder = CLGeocoder()
        var locality: String? = "Place"
        geocoder.reverseGeocodeLocation(self.clLocation) { (placemarks, error) in
            guard error == nil else {
                return
            }
            
            if let firstPlacemark = placemarks?.first {
                locality = firstPlacemark.locality
            }
        }
        
        return locality
    }
}

extension EarthquakeGeometry {
    init(type: String, coordinates: [Double]) {
        self.type = type
        self.coordinates = coordinates
    }
    
    static let testEarthquakeGeometry = EarthquakeGeometry(type: "Point", coordinates: [-116.7776667, 33.6633333, 11.008])
}
