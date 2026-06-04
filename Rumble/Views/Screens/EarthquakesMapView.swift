//
//  EarthquakesMapView.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/21/23.
//

import SwiftUI
import MapKit

struct EarthquakesMapView: View {
    var state: EarthquakesState

    @State private var selectedEarthquake: Earthquake?
    @State private var showingEarthquakePreview = false
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

    var earthquakes: [Earthquake] { state.earthquakes ?? [] }

    var body: some View {
        if earthquakes.isEmpty && !state.isLoading {
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
                UserAnnotation()
                ForEach(earthquakes, id: \.self) { quake in
                    let isSelected = selectedEarthquake == quake
                    Annotation(
                        "",
                        coordinate: quake.geometry.coordinate2D,
                        anchor: .center
                    ) {
                        EarthquakePin(
                            magnitude: quake.properties.magnitude,
                            isSelected: isSelected
                        )
                    }
                    .tag(quake.id)
                    .annotationTitles(.hidden)
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

struct EarthquakePin: View {
    let magnitude: Double
    let isSelected: Bool

    private var magnitudeLabel: String {
        if magnitude < 10 {
            return String(format: "%.1f", magnitude)
        }
        return String(format: "%.0f", magnitude)
    }

    var body: some View {
        Text(magnitudeLabel)
            .font(.system(size: isSelected ? 13 : 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
            .background(Color.magnitudeColor(for: magnitude), in: Circle())
            .shadow(color: Color.magnitudeColor(for: magnitude).opacity(0.5), radius: isSelected ? 6 : 3)
            .animation(.spring(duration: 0.3), value: isSelected)
    }
}

#Preview {
    EarthquakesMapView(state: .previewStateDefault)
}
