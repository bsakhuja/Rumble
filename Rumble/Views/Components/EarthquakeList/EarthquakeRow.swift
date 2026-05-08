//
//  EarthquakeRow.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/7/23.
//

import SwiftUI

struct EarthquakeRow: View {
    var earthquake: Earthquake

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Magnitude")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(preciseRound(earthquake.properties.magnitude, precision: .hundredths))
                    .font(.title)
                    .bold()
                    .foregroundStyle(Color.magnitudeColor(for: earthquake.properties.magnitude))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(earthquake.properties.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(earthquake.properties.place ?? "Unknown location")
                    .font(.subheadline)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    EarthquakeRow(earthquake: Earthquake.testEarthquake)
        .padding()
}
