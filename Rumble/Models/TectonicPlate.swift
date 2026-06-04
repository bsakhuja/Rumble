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
struct TectonicPlate {
    let name: String
    let labelCoordinate: CLLocationCoordinate2D
}

// Named fault/feature label for the map.
struct NamedFault {
    let name: String
    let type: BoundaryType
    let coordinate: CLLocationCoordinate2D
}

// One typed boundary polyline — sourced from TectonicBoundaryTypes.json.
struct PlateBoundarySegment {
    let type: BoundaryType
    let coordinates: [CLLocationCoordinate2D]
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
    let PlateName: String
}

struct PlateGeometry: Decodable {
    let allCoords: [[Double]]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(String.self, forKey: .type) {
        case "Polygon":
            allCoords = (try c.decode([[[Double]]].self, forKey: .coordinates)).first ?? []
        case "MultiPolygon":
            allCoords = (try c.decode([[[[Double]]]].self, forKey: .coordinates)).compactMap(\.first).flatMap { $0 }
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
    let t: BoundaryType
    let c: [[Double]]
}
