//
//  FloatingButtonView.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/21/23.
//

import SwiftUI

struct FloatingButtonView: View {
    let imageName: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: imageName)
                .font(.title.weight(.semibold))
                .padding()
                .glassEffect(.regular, in: Circle())
        }
    }
}

#Preview("List") {
    FloatingButtonView(imageName: "list.bullet") { }
}

#Preview("Map") {
    FloatingButtonView(imageName: "map") { }
}
