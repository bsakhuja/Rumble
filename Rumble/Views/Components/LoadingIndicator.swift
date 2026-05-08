//
//  LoadingIndicator.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/9/23.
//

import SwiftUI

struct LoadingIndicator: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading...")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    LoadingIndicator()
}
