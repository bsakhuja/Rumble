//
//  NetworkManager.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/7/23.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse(Int)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let code): return "Server returned an unexpected response (\(code))."
        case .invalidData: return "The earthquake data could not be read."
        }
    }
}

enum EarthquakeEndpoint {
    case query(startTime: String, endTime: String)

    var url: URL {
        var components = URLComponents(string: "https://earthquake.usgs.gov/fdsnws/event/1/query")!
        switch self {
        case .query(let startTime, let endTime):
            components.queryItems = [
                URLQueryItem(name: "format", value: "geojson"),
                URLQueryItem(name: "starttime", value: startTime),
                URLQueryItem(name: "endtime", value: endTime),
            ]
        }
        return components.url!
    }
}

struct NetworkClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch<T: Decodable>(_ endpoint: EarthquakeEndpoint) async throws -> T {
        var request = URLRequest(url: endpoint.url, cachePolicy: .returnCacheDataElseLoad)
        request.httpMethod = "GET"

        let maxRetries = 2
        var lastError: Error = APIError.invalidData
        for attempt in 0...maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse(0) }
                guard (200...299).contains(http.statusCode) else { throw APIError.invalidResponse(http.statusCode) }
                return try JSONDecoder().decode(T.self, from: data)
            } catch let urlError as URLError where attempt < maxRetries {
                lastError = urlError
                let delay: UInt64 = attempt == 0 ? 500_000_000 : 1_000_000_000
                try await Task.sleep(nanoseconds: delay)
            } catch {
                throw error
            }
        }
        throw lastError
    }
}

protocol EarthquakeServiceProtocol: Sendable {
    func getEarthquakes(startTime: Date, endTime: Date) async throws -> GeoJSON
}

struct EarthquakeService: EarthquakeServiceProtocol {
    private let client = NetworkClient()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func getEarthquakes(startTime: Date, endTime: Date) async throws -> GeoJSON {
        let start = dateFormatter.string(from: startTime)
        let end = dateFormatter.string(from: endTime.dayAfter)
        return try await client.fetch(.query(startTime: start, endTime: end))
    }
}
