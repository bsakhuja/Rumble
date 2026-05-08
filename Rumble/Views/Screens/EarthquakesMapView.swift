//
//  EarthquakesMapView.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/21/23.
//

import SwiftUI
import MapKit

struct EarthquakesMapView: View {
    @Environment(SettingsState.self) var settings
    var state: EarthquakesState

    @State private var selectedEarthquake: Earthquake?
    @State private var showingEarthquakePreview = false
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

    var filteredEarthquakes: [Earthquake] {
        (state.earthquakes ?? []).filter {
            $0.properties.magnitude < Double(settings.magnitudeUpper) &&
            $0.properties.magnitude > Double(settings.magnitudeLower)
        }
    }

    var body: some View {
        if filteredEarthquakes.isEmpty && !state.isLoading {
            VStack {
                Spacer()
                Image(systemName: "waveform.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("No earthquakes to show").font(.title3.weight(.medium))
                Text("Try adjusting your search settings").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            }
        } else {
            Map(position: $position, selection: $selectedEarthquake) {
                Marker(item: .forCurrentLocation())
                ForEach(filteredEarthquakes, id: \.self) { quake in
                    Marker(quake.properties.title, coordinate: quake.geometry.coordinate2D)
                        .tag(quake.id)
                        .tint(Color.magnitudeColor(for: quake.properties.magnitude))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    withAnimation { position = .userLocation(fallback: .automatic) }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .medium))
                        .padding(12)
                        .background(.regularMaterial, in: Circle())
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            .onChange(of: selectedEarthquake) {
                showingEarthquakePreview = selectedEarthquake != nil
            }
            .onChange(of: showingEarthquakePreview) {
                if !showingEarthquakePreview { selectedEarthquake = nil }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedEarthquake)
            .sheet(isPresented: $showingEarthquakePreview) {
                if let quake = selectedEarthquake {
                    EarthquakePreviewView(earthquake: quake)
                        .presentationDetents([.fraction(0.25)])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
}

#Preview {
    EarthquakesMapView(state: .previewStateDefault)
        .environment(SettingsState())
}
