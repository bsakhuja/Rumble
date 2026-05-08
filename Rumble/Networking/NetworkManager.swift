//
//  NetworkManager.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/7/23.
//

import Foundation
import Combine

// https://medium.com/@islammoussa.eg/swiftui-and-combine-building-a-solid-network-layer-for-handling-api-requests-5ccce878212a

protocol APIEndpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIError: Error {
    case invalidResponse
    case invalidData
}

protocol APIClient {
    associatedtype EndpointType: APIEndpoint
    func request<T: Decodable>(_ endpoint: EndpointType) -> AnyPublisher<T, Error>
}

enum EarthquakeEndpoint: APIEndpoint {
    case query(startTime: String, endTime: String)
    
    var baseURL: URL {
        // swiftlint:disable:next force_unwrapping
        return URL(string: "https://earthquake.usgs.gov/fdsnws/event/1")!
    }
    
    var path: String {
        switch self {
        case .query:
            return "/query"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .query:
            return .get
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .query:
            return ["Authorization": "Bearer TOKEN"]
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .query(let startTime, let endTime):
            return ["format": "geojson", "starttime": startTime, "endtime": endTime]
        }
    }
}

class URLSessionAPIClient<EndpointType: APIEndpoint>: APIClient {
    func request<T: Decodable>(_ endpoint: EndpointType) -> AnyPublisher<T, Error> {
        let url = endpoint.baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        endpoint.headers?.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        endpoint.parameters?.forEach { parameter in
            request.url?.append(queryItems: [
                URLQueryItem(name: parameter.key, value: "\(parameter.value)")
            ])
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

protocol EarthquakeServiceProtocol {
    func getEarthquakes(startTime: Date, endTime: Date) -> AnyPublisher<GeoJSON, Error>
}

class EarthquakeService: EarthquakeServiceProtocol {
    let apiClient = URLSessionAPIClient<EarthquakeEndpoint>()
    
    func getEarthquakes(startTime: Date, endTime: Date) -> AnyPublisher<GeoJSON, Error> {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startTimeString = dateFormatter.string(from: startTime)
        let endTimeString = dateFormatter.string(from: endTime.dayAfter)
        return apiClient.request(.query(startTime: startTimeString, endTime: endTimeString))
    }
}
