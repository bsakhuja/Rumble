//
//  EarthquakeDetailView.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/8/23.
//

import SwiftUI
import MapKit

struct EarthquakeDetailView: View {
    @Environment(SettingsState.self) var settings
    let earthquake: Earthquake

    var body: some View {
        List {
            Section("Earthquake specifics") {
                Text(earthquake.properties.title)
                HStack {
                    Text("Magnitude")
                    Spacer()
                    Text(preciseRound(earthquake.properties.magnitude, precision: .hundredths))
                        .bold()
                        .foregroundStyle(Color.magnitudeColor(for: earthquake.properties.magnitude))
                }
                HStack {
                    Text("Date & Time")
                    Spacer()
                    Text(earthquake.properties.date.formatted(.dateTime))
                }
                if let tsunami = earthquake.properties.tsunami {
                    HStack {
                        Text("Tsunami warning")
                        Spacer()
                        Text(tsunami ? "Yes" : "No")
                            .foregroundStyle(tsunami ? .red : .secondary)
                    }
                }
            }

            Section("Location") {
                if let place = earthquake.properties.place {
                    Text(place)
                }
                NavigationLink("View on map") {
                    Map(initialPosition: earthquake.geometry.mapCameraPosition) {
                        Marker(earthquake.properties.place ?? "Earthquake", coordinate: earthquake.geometry.coordinate2D)
                            .tint(Color.magnitudeColor(for: earthquake.properties.magnitude))
                    }
                    .navigationTitle("Earthquake location")
                }
                if let location = settings.userLocation {
                    HStack {
                        Text("Distance from you")
                        Spacer()
                        Text("\(Int(earthquake.geometry.clLocation.distance(from: location) / 1000)) km")
                    }
                }
            }

            Section("Extra") {
                if let url = earthquake.properties.url {
                    HStack {
                        Text("Additional details")
                        Spacer()
                        Link("View on USGS", destination: url)
                    }
                }
                if let didYouFeelItURL = earthquake.properties.didYouFeelItUrl {
                    HStack {
                        Text("Did you feel it?")
                        Spacer()
                        Link("Report to USGS", destination: didYouFeelItURL)
                    }
                }
            }
        }
        .navigationTitle("Earthquake details")
    }
}

#Preview {
    NavigationStack {
        EarthquakeDetailView(earthquake: Earthquake.testEarthquake)
            .environment(SettingsState())
    }
}
