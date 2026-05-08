//
//  EarthquakesState.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/7/23.
//

import Foundation
import Combine
import SwiftUI

class EarthquakesState: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    let earthquakeService: EarthquakeServiceProtocol
    @Published var earthquakes: [Earthquake]?
    @Published var isLoading: Bool = true
    @Published var shouldShowFloatingButton: Bool = true
    
    @EnvironmentObject var settings: SettingsState
    
    init(earthquakeService: EarthquakeServiceProtocol) {
        self.earthquakeService = earthquakeService
    }
    
    func fetchEarthquakes(startTime: Date, endTime: Date) {
        isLoading = true
        earthquakeService.getEarthquakes(startTime: startTime, endTime: endTime)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
            
        }, receiveValue: { [weak self] data in
            self?.earthquakes = data.earthquakes
            self?.isLoading = false
        }).store(in: &cancellables)
    }
    
    // MARK: - Preview States
    
    static var previewStateDefault: EarthquakesState = {
        var state = EarthquakesState(earthquakeService: EarthquakeService())
        state.earthquakes = [
            Earthquake.testEarthquake
        ]
        return state
    }()
    
    static var previewStateLoading: EarthquakesState = {
        var state = EarthquakesState(earthquakeService: EarthquakeService())
        state.isLoading = true
        return state
    }()
    
}
