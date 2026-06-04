//
//  TectonicPlateLoader.swift
//  Rumble
//

import CoreLocation

@MainActor
enum TectonicPlateLoader {
    private static var _plates: [TectonicPlate]?
    private static var _boundaries: [PlateBoundarySegment]?

    // MARK: - Public API

    /// Plate labels with curated positions for major plates.
    static func loadPlates() -> [TectonicPlate] {
        if let cached = _plates { return cached }

        guard let url = Bundle.main.url(forResource: "TectonicPlates", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let collection = try? JSONDecoder().decode(TectonicFeatureCollection.self, from: data) else {
            return []
        }

        // Deduplicate by name, using curated positions where available
        var seen = Set<String>()
        let plates: [TectonicPlate] = collection.features.compactMap { feature in
            let name = feature.properties.PlateName
            guard !seen.contains(name) else { return nil }
            seen.insert(name)
            let coord = labelOverrides[name] ?? boundingBoxCenter(feature.geometry.allCoords)
            return TectonicPlate(name: name, labelCoordinate: coord)
        }

        _plates = plates
        return plates
    }

    /// Typed boundary polylines from TectonicBoundaryTypes.json (per-segment convergent/divergent/transform).
    static func loadBoundaries() -> [PlateBoundarySegment] {
        if let cached = _boundaries { return cached }

        guard let url = Bundle.main.url(forResource: "TectonicBoundaryTypes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let collection = try? JSONDecoder().decode(CompactBoundaryCollection.self, from: data) else {
            return []
        }

        let segments = collection.features.flatMap { feature -> [PlateBoundarySegment] in
            let coords = feature.c.compactMap { pair -> CLLocationCoordinate2D? in
                guard pair.count >= 2 else { return nil }
                return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
            }
            return splitAtAntimeridian(coords).map { PlateBoundarySegment(type: feature.t, coordinates: $0) }
        }

        _boundaries = segments
        return segments
    }

    // MARK: - Helpers

    nonisolated static func splitAtAntimeridian(_ coords: [CLLocationCoordinate2D]) -> [[CLLocationCoordinate2D]] {
        guard coords.count > 1 else { return [] }
        var segments: [[CLLocationCoordinate2D]] = []
        var current = [coords[0]]
        for idx in 1..<coords.count {
            if abs(coords[idx].longitude - coords[idx - 1].longitude) > 180 {
                if current.count > 1 { segments.append(current) }
                current = [coords[idx]]
            } else {
                current.append(coords[idx])
            }
        }
        if current.count > 1 { segments.append(current) }
        return segments
    }

    nonisolated static func boundingBoxCenter(_ coords: [[Double]]) -> CLLocationCoordinate2D {
        let lats = coords.compactMap { $0.count >= 2 ? $0[1] : nil }
        let lons = coords.compactMap { $0.count >= 2 ? $0[0] : nil }
        let lat = ((lats.min() ?? 0) + (lats.max() ?? 0)) / 2
        let lon = ((lons.min() ?? 0) + (lons.max() ?? 0)) / 2
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // MARK: - Curated label positions for plates whose bounding-box centroid is misleading

    // swiftlint:disable comma
    private static let labelOverrides: [String: CLLocationCoordinate2D] = [
        "Pacific": .init(latitude: 5, longitude: -165),
        "North America": .init(latitude: 55, longitude: -100),
        "South America": .init(latitude: -15, longitude: -55),
        "Africa": .init(latitude: 5, longitude: 20),
        "Eurasia": .init(latitude: 55, longitude: 65),
        "Australia": .init(latitude: -25, longitude: 133),
        "Antarctica": .init(latitude: -80, longitude: 0),
        "Arabia": .init(latitude: 23, longitude: 45),
        "Somalia": .init(latitude: 5, longitude: 52),
        "India": .init(latitude: 20, longitude: 78),
        "Nazca": .init(latitude: -18, longitude: -98),
        "Caribbean": .init(latitude: 15, longitude: -75),
        "Philippine Sea": .init(latitude: 18, longitude: 138),
        "Juan de Fuca": .init(latitude: 47, longitude: -129),
        "Cocos": .init(latitude: 12, longitude: -103),
        "Amur": .init(latitude: 52, longitude: 130),
        "Okhotsk": .init(latitude: 55, longitude: 152),
        "Scotia": .init(latitude: -57, longitude: -40),
        "Sunda": .init(latitude: -3, longitude: 110),
        "Yangtze": .init(latitude: 30, longitude: 117),
        "Tonga": .init(latitude: -20, longitude: -175),
        "Kermadec": .init(latitude: -30, longitude: -178),
        "Burma": .init(latitude: 22, longitude: 95),
        "Okinawa": .init(latitude: 27, longitude: 128),
        "North Andes": .init(latitude: 2, longitude: -77),
        "Altiplano": .init(latitude: -17, longitude: -68),
        "Rivera": .init(latitude: 19, longitude: -107),
        "Aegean Sea": .init(latitude: 38, longitude: 24),
        "Anatolia": .init(latitude: 39, longitude: 33),
        "New Hebrides": .init(latitude: -15, longitude: 167),
        "Mariana": .init(latitude: 18, longitude: 147),
        "Caroline": .init(latitude: 5, longitude: 149),
        "Woodlark": .init(latitude: -8, longitude: 153),
        "Easter": .init(latitude: -25, longitude: -105),
        "Juan Fernandez": .init(latitude: -33, longitude: -85),
        "Galapagos": .init(latitude: 1, longitude: -90),
        "Sandwich": .init(latitude: -57, longitude: -26),
        "Shetland": .init(latitude: -63, longitude: -55),
        "Manus": .init(latitude: -2, longitude: 146),
        "North Bismarck": .init(latitude: -2, longitude: 149),
        "South Bismarck": .init(latitude: -6, longitude: 150),
        "Solomon Sea": .init(latitude: -7, longitude: 152),
        "Molucca Sea": .init(latitude: 1, longitude: 127),
        "Banda Sea": .init(latitude: -5, longitude: 124),
        "Timor": .init(latitude: -9, longitude: 125),
        "Maoke": .init(latitude: -4, longitude: 136),
        "Birds Head": .init(latitude: -1, longitude: 131),
        "Niuafo'ou": .init(latitude: -17, longitude: -173),
        "Conway Reef": .init(latitude: -20, longitude: 174),
        "Balmoral Reef": .init(latitude: -17, longitude: 169),
        "Futuna": .init(latitude: -14, longitude: -178),
        "Panama": .init(latitude: 8, longitude: -80)
    ]
    // swiftlint:enable comma

    // MARK: - Named faults & features

    // swiftlint:disable function_body_length
    static let namedFaults: [NamedFault] = [
        // Divergent — mid-ocean ridges & rifts
        .init(name: "Mid-Atlantic Ridge", type: .divergent, coordinate: .init(latitude: 30, longitude: -40)),
        .init(name: "East Pacific Rise", type: .divergent, coordinate: .init(latitude: -15, longitude: -112)),
        .init(name: "Gakkel Ridge", type: .divergent, coordinate: .init(latitude: 85, longitude: 100)),
        .init(name: "Southwest Indian Ridge", type: .divergent, coordinate: .init(latitude: -45, longitude: 35)),
        .init(name: "Southeast Indian Ridge", type: .divergent, coordinate: .init(latitude: -45, longitude: 100)),
        .init(name: "Central Indian Ridge", type: .divergent, coordinate: .init(latitude: -15, longitude: 65)),
        .init(name: "Pacific-Antarctic Ridge", type: .divergent, coordinate: .init(latitude: -60, longitude: -150)),
        .init(name: "Chile Rise", type: .divergent, coordinate: .init(latitude: -43, longitude: -82)),
        .init(name: "East African Rift", type: .divergent, coordinate: .init(latitude: 0, longitude: 36)),
        .init(name: "Red Sea Rift", type: .divergent, coordinate: .init(latitude: 20, longitude: 39)),
        .init(name: "Gulf of Aden Ridge", type: .divergent, coordinate: .init(latitude: 12, longitude: 47)),
        .init(name: "Reykjanes Ridge", type: .divergent, coordinate: .init(latitude: 58, longitude: -30)),
        .init(name: "Kolbeinsey Ridge", type: .divergent, coordinate: .init(latitude: 68, longitude: -17)),

        // Convergent — subduction zones & trenches
        .init(name: "Mariana Trench", type: .convergent, coordinate: .init(latitude: 15, longitude: 147)),
        .init(name: "Japan Trench", type: .convergent, coordinate: .init(latitude: 37, longitude: 144)),
        .init(name: "Kuril-Kamchatka Trench", type: .convergent, coordinate: .init(latitude: 47, longitude: 155)),
        .init(name: "Peru-Chile Trench", type: .convergent, coordinate: .init(latitude: -23, longitude: -71)),
        .init(name: "Tonga Trench", type: .convergent, coordinate: .init(latitude: -20, longitude: -173)),
        .init(name: "Cascadia Subduction Zone", type: .convergent, coordinate: .init(latitude: 45, longitude: -125)),
        .init(name: "Sunda Trench", type: .convergent, coordinate: .init(latitude: -8, longitude: 105)),
        .init(name: "Philippine Trench", type: .convergent, coordinate: .init(latitude: 8, longitude: 127)),
        .init(name: "Aleutian Trench", type: .convergent, coordinate: .init(latitude: 51, longitude: 177)),
        .init(name: "Ryukyu Trench", type: .convergent, coordinate: .init(latitude: 27, longitude: 130)),
        .init(name: "Himalayas", type: .convergent, coordinate: .init(latitude: 29, longitude: 85)),
        .init(name: "Zagros Collision Zone", type: .convergent, coordinate: .init(latitude: 33, longitude: 50)),
        .init(name: "Hellenic Trench", type: .convergent, coordinate: .init(latitude: 35, longitude: 23)),
        .init(name: "Middle America Trench", type: .convergent, coordinate: .init(latitude: 14, longitude: -93)),
        .init(name: "Puerto Rico Trench", type: .convergent, coordinate: .init(latitude: 19, longitude: -66)),
        .init(name: "Kermadec Trench", type: .convergent, coordinate: .init(latitude: -30, longitude: -176)),
        .init(name: "New Hebrides Trench", type: .convergent, coordinate: .init(latitude: -16, longitude: 168)),

        // Transform — major faults
        .init(name: "San Andreas Fault", type: .transform, coordinate: .init(latitude: 36, longitude: -120)),
        .init(name: "Alpine Fault", type: .transform, coordinate: .init(latitude: -43, longitude: 170)),
        .init(name: "North Anatolian Fault", type: .transform, coordinate: .init(latitude: 41, longitude: 33)),
        .init(name: "Dead Sea Transform", type: .transform, coordinate: .init(latitude: 31, longitude: 35)),
        .init(name: "Queen Charlotte Fault", type: .transform, coordinate: .init(latitude: 53, longitude: -133)),
        .init(name: "Chaman Fault", type: .transform, coordinate: .init(latitude: 31, longitude: 67)),
        .init(name: "Owen Fracture Zone", type: .transform, coordinate: .init(latitude: 14, longitude: 58))
    ]
    // swiftlint:enable function_body_length
}
