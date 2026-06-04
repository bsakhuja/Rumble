//
//  TectonicPlate.swift
//  Rumble
//

import CoreLocation
import SwiftUI

enum BoundaryType: String, Decodable {
    case convergent = "c"
    case divergent  = "d"
    case transform  = "t"

    var displayName: String {
        switch self {
        case .convergent: return "Convergent"
        case .divergent:  return "Divergent"
        case .transform:  return "Transform"
        }
    }

    var color: Color {
        switch self {
        case .convergent: return .red
        case .divergent:  return Color(red: 0.0, green: 0.75, blue: 0.9)
        case .transform:  return Color(red: 1.0, green: 0.70, blue: 0.0)
        }
    }
}

// Label position + plate name — sourced from TectonicPlates.json.
struct TectonicPlate: Identifiable {
    let id: String
    let name: String
    let labelCoordinate: CLLocationCoordinate2D

    init(name: String, labelCoordinate: CLLocationCoordinate2D) {
        self.id = name
        self.name = name
        self.labelCoordinate = labelCoordinate
    }
}

// Named fault/feature label for the map.
struct NamedFault: Identifiable {
    let id: String
    let name: String
    let type: BoundaryType
    let coordinate: CLLocationCoordinate2D

    init(name: String, type: BoundaryType, coordinate: CLLocationCoordinate2D) {
        self.id = name
        self.name = name
        self.type = type
        self.coordinate = coordinate
    }
}

// One typed boundary polyline — sourced from TectonicBoundaryTypes.json.
struct PlateBoundarySegment: Identifiable {
    let id: Int
    let type: BoundaryType
    let coordinates: [CLLocationCoordinate2D]
    /// Bounding box for fast viewport intersection checks.
    let minLat: Double
    let maxLat: Double
    let minLon: Double
    let maxLon: Double

    init(id: Int, type: BoundaryType, coordinates: [CLLocationCoordinate2D]) {
        self.id = id
        self.type = type
        self.coordinates = coordinates
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        self.minLat = lats.min() ?? 0
        self.maxLat = lats.max() ?? 0
        self.minLon = lons.min() ?? 0
        self.maxLon = lons.max() ?? 0
    }
}

// MARK: - GeoJSON decoding for TectonicPlates.json

struct TectonicFeatureCollection: Decodable {
    let features: [TectonicFeature]
}

struct TectonicFeature: Decodable {
    let properties: TectonicProperties
    let geometry: PlateGeometry
}

struct TectonicProperties: Decodable {
    // swiftlint:disable:next identifier_name
    let PlateName: String
}

struct PlateGeometry: Decodable {
    let allCoords: [[Double]]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .type) {
        case "Polygon":
            allCoords = (try container.decode([[[Double]]].self, forKey: .coordinates)).first ?? []
        case "MultiPolygon":
            allCoords = (try container.decode([[[[Double]]]].self, forKey: .coordinates)).compactMap(\.first).flatMap { $0 }
        default:
            allCoords = []
        }
    }

    private enum CodingKeys: String, CodingKey { case type, coordinates }
}

// MARK: - Compact decoding for TectonicBoundaryTypes.json

struct CompactBoundaryCollection: Decodable {
    let features: [CompactBoundaryFeature]
}

struct CompactBoundaryFeature: Decodable {
    let type: BoundaryType
    let coords: [[Double]]

    private enum CodingKeys: String, CodingKey {
        case type = "t"
        case coords = "c"
    }
}
