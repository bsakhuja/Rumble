//
//  EarthquakesState.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/7/23.
//

import Foundation
import Observation

@Observable
@MainActor
final class EarthquakesState {
    let earthquakeService: EarthquakeServiceProtocol
    var earthquakes: [Earthquake]?
    var isLoading: Bool = true
    var error: Error?

    private var fetchTask: Task<Void, Never>?

    init(earthquakeService: EarthquakeServiceProtocol = EarthquakeService()) {
        self.earthquakeService = earthquakeService
    }

    func fetchEarthquakes(startTime: Date, endTime: Date) {
        fetchTask?.cancel()
        error = nil
        isLoading = true
        fetchTask = Task {
            do {
                let result = try await earthquakeService.getEarthquakes(startTime: startTime, endTime: endTime)
                guard !Task.isCancelled else { return }
                earthquakes = result.earthquakes
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error
                isLoading = false
            }
        }
    }

    // MARK: - Preview States

    static var previewStateDefault: EarthquakesState = {
        let state = EarthquakesState()
        state.earthquakes = [Earthquake.testEarthquake]
        state.isLoading = false
        return state
    }()

    static var previewStateLoading: EarthquakesState = {
        let state = EarthquakesState()
        state.isLoading = true
        return state
    }()
}
