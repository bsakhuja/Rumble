//
//  EarthquakesMapView.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/21/23.
//

import SwiftUI
import MapKit

struct EarthquakesMapView: View {
    
    @ObservedObject var state: EarthquakesState
    @EnvironmentObject var settings: SettingsState
    
    var initialMapCameraPosition: MapCameraPosition {
        MapCameraPosition.userLocation(fallback: .automatic)
    }
    
    @State private var selectedEarthquake: Earthquake?
    @State private var showingEarthquakePreview = false
    
    var filteredEarthquakes: [Earthquake]? {
        state.earthquakes?.filter {
            $0.properties.magnitude < Double(settings.magnitudeUpper) &&
            $0.properties.magnitude > Double(settings.magnitudeLower)
        }
    }
    
    var body: some View {
        if let earthquakes = filteredEarthquakes,
           !earthquakes.isEmpty {
            Map(initialPosition: initialMapCameraPosition,
                selection: $selectedEarthquake) {
                Marker(item: .forCurrentLocation())
                ForEach(earthquakes, id: \.self) { result in
                    Marker(result.properties.title, coordinate: result.geometry.coordinate2D)
                        .tag(result.id)
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .onChange(of: selectedEarthquake) {
                showingEarthquakePreview = selectedEarthquake != nil
            }
            .onChange(of: showingEarthquakePreview) {
                if !showingEarthquakePreview {
                    selectedEarthquake = nil
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedEarthquake)
            .sheet(isPresented: $showingEarthquakePreview, content: {
                if let earthquake = selectedEarthquake {
                    EarthquakePreviewView(earthquake: earthquake)
                        .presentationDetents([.fraction(0.25)])
                        .presentationDragIndicator(.visible)
                }
            })
        } else {
            VStack {
                Spacer()
                Text("No earthquakes to show").font(.title)
                Text("Try adjusting your search settings").font(.subheadline)
                Spacer()
            }
            
        }
        
    }
}

#Preview {
    EarthquakesMapView(state: .previewStateDefault)
}
