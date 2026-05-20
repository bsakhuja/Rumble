//
//  EarthquakePreviewView.swift
//  Rumble
//
//  Created by Brian Sakhuja on 3/7/24.
//

import SwiftUI

struct EarthquakePreviewView: View {
    @State private var isShowingDetails = false
    let earthquake: Earthquake

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(earthquake.properties.title) {
                isShowingDetails = true
            }
            .font(.headline)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)

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
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .padding()
        .sheet(isPresented: $isShowingDetails) {
            NavigationStack {
                EarthquakeDetailView(earthquake: earthquake)
            }
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    EarthquakePreviewView(earthquake: Earthquake.testEarthquake)
        .environment(SettingsState())
}
