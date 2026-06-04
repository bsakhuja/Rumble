//
//  RumbleTests.swift
//  RumbleTests
//
//  Created by Brian Sakhuja on 11/7/23.
//

import XCTest
import CoreLocation
@testable import Rumble

actor MockEarthquakeService: EarthquakeServiceProtocol {
    var capturedMin: Int?
    var capturedMax: Int?

    func getEarthquakes(startTime: Date, endTime: Date, minMagnitude: Int, maxMagnitude: Int) async throws -> GeoJSON {
        capturedMin = minMagnitude
        capturedMax = maxMagnitude
        return GeoJSON()
    }
}

final class RumbleTests: XCTestCase {

    // MARK: - EarthquakeEndpoint URL builder

    func testBuildURL_includesMinMagnitude() throws {
        let url = try EarthquakeEndpoint.query(
            startTime: "2024-01-01", endTime: "2024-01-02",
            minMagnitude: 3, maxMagnitude: 10
        ).buildURL()
        XCTAssertTrue(url.absoluteString.contains("minmagnitude=3"))
        XCTAssertFalse(url.absoluteString.contains("maxmagnitude"))
    }

    func testBuildURL_includesMaxMagnitudeWhenBelowTen() throws {
        let url = try EarthquakeEndpoint.query(
            startTime: "2024-01-01", endTime: "2024-01-02",
            minMagnitude: 2, maxMagnitude: 7
        ).buildURL()
        XCTAssertTrue(url.absoluteString.contains("minmagnitude=2"))
        XCTAssertTrue(url.absoluteString.contains("maxmagnitude=7"))
    }

    // MARK: - EarthquakesState passthrough

    func testFetchEarthquakes_passesMagnitudeToService() async throws {
        let mock = MockEarthquakeService()
        let state = await EarthquakesState(earthquakeService: mock)
        await state.fetchEarthquakes(startTime: .now, endTime: .now, minMagnitude: 4, maxMagnitude: 8)
        // Allow the internal Task to complete before asserting.
        try await Task.sleep(nanoseconds: 100_000_000)
        let min = await mock.capturedMin
        let max = await mock.capturedMax
        XCTAssertEqual(min, 4)
        XCTAssertEqual(max, 8)
    }

    // MARK: - GeoJSON decoder

    func testGeoJSONDecoderDecodesQuake() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let quake = try decoder.decode(EarthquakeProperties.self, from: testFeature_nc73649170)
        
        XCTAssertEqual(quake.code, "73649170")
        
        let expectedSeconds = TimeInterval(1636129710550) / 1000
        let decodedSeconds = quake.date.timeIntervalSince1970
        
        
        XCTAssertEqual(expectedSeconds, decodedSeconds, accuracy: 0.00001)
    }
    
    func testGeoJSONDecoderDecodesGeoJSON() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decoded = try decoder.decode(GeoJSON.self, from: testQuakesData)


        XCTAssertEqual(decoded.earthquakes.count, 6)
        XCTAssertEqual(decoded.earthquakes[0].properties.code, "73649170")


        let expectedSeconds = TimeInterval(1636129710550) / 1000
        let decodedSeconds = decoded.earthquakes[0].properties.date.timeIntervalSince1970
        XCTAssertEqual(expectedSeconds, decodedSeconds, accuracy: 0.00001)
    }

    // MARK: - TectonicPlateLoader

    @MainActor
    func testTectonicPlateLoader_parsesExpectedPlateCount() {
        let plates = TectonicPlateLoader.loadPlates()
        XCTAssertFalse(plates.isEmpty, "Should load at least one plate")
        // 54 raw features deduped by name → 52 unique plates (Kermadec and Balmoral Reef each appear twice)
        XCTAssertEqual(plates.count, 52, "Expected 52 unique named plates after deduplication")
    }

    @MainActor
    func testTectonicPlateLoader_knownPlatesPresent() {
        let plates = TectonicPlateLoader.loadPlates()
        let names = Set(plates.map(\.name))
        XCTAssertTrue(names.contains("Pacific"), "Pacific Plate should be present")
        XCTAssertTrue(names.contains("Africa"), "African Plate should be present")
        XCTAssertTrue(names.contains("North America"), "North American Plate should be present")
    }

    @MainActor
    func testTectonicPlateLoader_boundariesLoad() {
        let segments = TectonicPlateLoader.loadBoundaries()
        XCTAssertFalse(segments.isEmpty, "Should load boundary segments")
        for seg in segments {
            XCTAssertGreaterThanOrEqual(seg.coordinates.count, 2, "Each segment needs at least 2 coords")
        }
        // All three boundary types should be present
        let types = Set(segments.map(\.type))
        XCTAssertTrue(types.contains(.convergent))
        XCTAssertTrue(types.contains(.divergent))
        XCTAssertTrue(types.contains(.transform))
    }

    // MARK: - Antimeridian splitting

    func testSplitAtAntimeridian_noSplitNeeded() {
        let coords = [
            CLLocationCoordinate2D(latitude: 0, longitude: 10),
            CLLocationCoordinate2D(latitude: 0, longitude: 20),
            CLLocationCoordinate2D(latitude: 0, longitude: 30),
        ]
        let segments = TectonicPlateLoader.splitAtAntimeridian(coords)
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].count, 3)
    }

    func testSplitAtAntimeridian_splitsAtLargeLongitudeJump() {
        let coords = [
            CLLocationCoordinate2D(latitude: 0, longitude: 160),
            CLLocationCoordinate2D(latitude: 0, longitude: 170),
            CLLocationCoordinate2D(latitude: 0, longitude: -170),
            CLLocationCoordinate2D(latitude: 0, longitude: -160),
        ]
        let segments = TectonicPlateLoader.splitAtAntimeridian(coords)
        XCTAssertEqual(segments.count, 2, "Should split into two segments at the antimeridian crossing")
        XCTAssertEqual(segments[0].count, 2)
        XCTAssertEqual(segments[1].count, 2)
    }

    func testSplitAtAntimeridian_emptyInput() {
        let segments = TectonicPlateLoader.splitAtAntimeridian([])
        XCTAssertTrue(segments.isEmpty)
    }

    func testSplitAtAntimeridian_singlePoint() {
        let coords = [CLLocationCoordinate2D(latitude: 0, longitude: 0)]
        let segments = TectonicPlateLoader.splitAtAntimeridian(coords)
        XCTAssertTrue(segments.isEmpty, "Single point has no line segments to render")
    }
}
