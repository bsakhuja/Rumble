//
//  EarthquakeProperties.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/7/23.
//

import Foundation

struct Quakes: Codable {
    let quakes: [Quakes]
}

struct EarthquakeProperties: Identifiable {
    
    let magnitude: Double
    let place: String?
    let time: Double
    let code: String
    let detail: URL?
    var id: String { code }
    let tsunami: Bool?
    let title: String
    let url: URL?
    
    var didYouFeelItUrl: URL? {
        url?.appendingPathComponent("/tellus")
    }
    
    var date: Date {
        Date(timeIntervalSince1970: time / 1000)
    }
}

extension EarthquakeProperties: Decodable {
    private enum CodingKeys: String, CodingKey {
        case magnitude = "mag"
        case place
        case time
        case code
        case detail
        case tsunami
        case title
        case url
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawMagnitude = try? values.decode(Double.self, forKey: .magnitude)
        let rawPlace = try? values.decode(String.self, forKey: .place)
        let rawTime = try? values.decode(Double.self, forKey: .time)
        let rawCode = try? values.decode(String.self, forKey: .code)
        let rawDetail = try? values.decode(URL.self, forKey: .detail)
        let rawTsunami = try? values.decode(Bool.self, forKey: .tsunami)
        let rawTitle = try? values.decode(String.self, forKey: .title)
        let rawURL = try? values.decode(String.self, forKey: .url)
        
        guard let magnitude = rawMagnitude,
              let time = rawTime,
              let code = rawCode,
              let detail = rawDetail,
              let title = rawTitle,
              let urlString = rawURL,
              let url = URL(string: urlString)
        else {
            throw QuakeError.missingData
        }
        
        self.magnitude = magnitude
        self.place = rawPlace
        self.time = time
        self.code = code
        self.detail = detail
        self.tsunami = rawTsunami
        self.title = title
        self.url = url
    }
}

extension EarthquakeProperties {
    static let testEarthquakeProperties = EarthquakeProperties(magnitude: 2.4, place: "10km SSW of Idyllwild, CA", time: 1388620296020, code: "code", detail: nil, tsunami: false, title: "M 1.3 - 10km SSW of Idyllwild, CA", url: URL(string: "https://earthquake.usgs.gov/earthquakes/eventpage/tx2024eqpe"))
}
