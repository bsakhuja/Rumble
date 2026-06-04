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
    @Environment(SettingsState.self) var settings

    @State private var selectedEarthquake: Earthquake?
    @State private var showingEarthquakePreview = false
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var boundaries: [PlateBoundarySegment] = []
    @State private var plates: [TectonicPlate] = []

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
                if settings.showPlateBoundaries {
                    ForEach(boundaries.indices, id: \.self) { i in
                        MapPolyline(coordinates: boundaries[i].coordinates)
                            .stroke(boundaries[i].type.color.opacity(0.75), lineWidth: 1.5)
                    }
                    ForEach(plates.indices, id: \.self) { i in
                        Annotation("", coordinate: plates[i].labelCoordinate) {
                            HStack(spacing: 4) {
                                Image(systemName: "globe.americas.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                                Text(plates[i].name)
                                    .font(.caption2.weight(.medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 5))
                        }
                    }
                    ForEach(TectonicPlateLoader.namedFaults.indices, id: \.self) { i in
                        let fault = TectonicPlateLoader.namedFaults[i]
                        Annotation("", coordinate: fault.coordinate) {
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(fault.type.color)
                                    .frame(width: 3, height: 12)
                                Text(fault.name)
                                    .font(.system(size: 9, weight: .medium))
                                    .italic()
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }

                Marker(item: .forCurrentLocation())
                ForEach(earthquakes, id: \.self) { quake in
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
            .overlay(alignment: .bottomLeading) {
                if settings.showPlateBoundaries {
                    BoundaryTypeLegend()
                        .padding(16)
                }
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
            .task {
                if boundaries.isEmpty {
                    boundaries = TectonicPlateLoader.loadBoundaries()
                    plates = TectonicPlateLoader.loadPlates()
                }
            }
        }
    }
}

private struct BoundaryTypeLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach([BoundaryType.convergent, .divergent, .transform], id: \.rawValue) { type in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(type.color)
                        .frame(width: 18, height: 3)
                    Text(type.displayName)
                        .font(.caption2)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    EarthquakesMapView(state: .previewStateDefault)
        .environment(SettingsState())
}
