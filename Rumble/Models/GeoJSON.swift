//
//  GeoJSON.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/7/23.
//

import Foundation

struct GeoJSON: Decodable {
    
    private(set) var earthquakes: [Earthquake] = [] // AKA "features"
    
    private enum RootCodingKeys: String, CodingKey {
        case features
    }

    init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: RootCodingKeys.self)
        let earthquakes = try rootContainer.decode([Earthquake].self, forKey: .features)
        self.earthquakes = earthquakes
    }
}
