//
//  EarthquakeListView.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/21/23.
//

import SwiftUI
import CoreLocation

struct EarthquakeListView: View {
    @Environment(SettingsState.self) var settings
    var state: EarthquakesState

    var filteredEarthquakes: [Earthquake] {
        let base = state.earthquakes ?? []
        let magnitudeFiltered = base.filter {
            $0.properties.magnitude < Double(settings.magnitudeUpper) &&
            $0.properties.magnitude > Double(settings.magnitudeLower)
        }
        switch settings.sortMethod {
        case .none:
            return magnitudeFiltered
        case .locationAscending:
            guard let loc = settings.userLocation else { return magnitudeFiltered }
            return magnitudeFiltered.sorted { $0.geometry.clLocation.distance(from: loc) < $1.geometry.clLocation.distance(from: loc) }
        case .locationDescending:
            guard let loc = settings.userLocation else { return magnitudeFiltered }
            return magnitudeFiltered.sorted { $0.geometry.clLocation.distance(from: loc) > $1.geometry.clLocation.distance(from: loc) }
        case .magnitudeAscending:
            return magnitudeFiltered.sorted { $0.properties.magnitude < $1.properties.magnitude }
        case .magnitudeDescending:
            return magnitudeFiltered.sorted { $0.properties.magnitude > $1.properties.magnitude }
        case .timeAscending:
            return magnitudeFiltered.sorted { $0.properties.time < $1.properties.time }
        case .timeDescending:
            return magnitudeFiltered.sorted { $0.properties.time > $1.properties.time }
        }
    }

    var body: some View {
        Group {
            if state.isLoading {
                Color.clear
            } else if filteredEarthquakes.isEmpty {
                emptyStateView
            } else {
                earthquakeList
            }
        }
    }

    private var earthquakeList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredEarthquakes, id: \.self) { earthquake in
                    earthquakeRow(earthquake)
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            state.fetchEarthquakes(startTime: settings.dateStart, endTime: settings.dateEnd)
        }
    }

    @ViewBuilder
    private func earthquakeRow(_ earthquake: Earthquake) -> some View {
        NavigationLink {
            EarthquakeDetailView(earthquake: earthquake)
        } label: {
            EarthquakeRow(earthquake: earthquake)
                .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "waveform.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No earthquakes in this range")
                .font(.title3.weight(.medium))
            Text("Try adjusting the filters above")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}

// MARK: - Filter Bar

struct FilterBarView: View {
    @Environment(SettingsState.self) var settings
    @State private var showMagnitudeFilter = false

    var body: some View {
        @Bindable var settings = settings
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Date chip
                Menu {
                    Picker("Date Range", selection: $settings.dateRangeDays) {
                        Text("Today").tag(1)
                        Text("3 Days").tag(3)
                        Text("7 Days").tag(7)
                        Text("14 Days").tag(14)
                        Text("30 Days").tag(30)
                    }
                } label: {
                    Label(dateLabel, systemImage: "calendar")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)

                // Magnitude chip
                Button {
                    showMagnitudeFilter.toggle()
                } label: {
                    Label(magnitudeLabel, systemImage: "waveform")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .popover(isPresented: $showMagnitudeFilter) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Magnitude Range")
                            .font(.headline)
                        Stepper(
                            "Min: M\(settings.magnitudeLower)",
                            value: $settings.magnitudeLower,
                            in: 0...(settings.magnitudeUpper - 1)
                        )
                        Stepper(
                            "Max: M\(settings.magnitudeUpper)",
                            value: $settings.magnitudeUpper,
                            in: (settings.magnitudeLower + 1)...10
                        )
                    }
                    .padding()
                    .presentationCompactAdaptation(.popover)
                }

                // Sort chip
                Menu {
                    Picker("Sort", selection: $settings.sortMethod) {
                        ForEach(SortMethod.allCases, id: \.self) { method in
                            Text(method.shortName).tag(method)
                        }
                    }
                } label: {
                    Label(sortLabel, systemImage: sortIcon)
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var dateLabel: String {
        switch settings.dateRangeDays {
        case 1: return "Today"
        case 3: return "3 Days"
        case 7: return "7 Days"
        case 14: return "14 Days"
        case 30: return "30 Days"
        default: return "\(settings.dateRangeDays) Days"
        }
    }

    private var magnitudeLabel: String {
        settings.magnitudeUpper >= 10
            ? "M\(settings.magnitudeLower)+"
            : "M\(settings.magnitudeLower)–\(settings.magnitudeUpper)"
    }

    private var sortLabel: String {
        settings.sortMethod == .none ? "Sort" : settings.sortMethod.shortName
    }

    private var sortIcon: String {
        switch settings.sortMethod {
        case .none: return "arrow.up.arrow.down"
        case .locationAscending, .magnitudeAscending, .timeAscending: return "arrow.up"
        case .locationDescending, .magnitudeDescending, .timeDescending: return "arrow.down"
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    NavigationStack {
        EarthquakeListView(state: .previewStateDefault)
    }
    .environment(SettingsState())
}

#Preview("Loading") {
    NavigationStack {
        EarthquakeListView(state: .previewStateLoading)
    }
    .environment(SettingsState())
}
