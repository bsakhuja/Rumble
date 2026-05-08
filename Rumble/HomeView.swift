//
//  HomeView.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/7/23.
//

import SwiftUI

struct HomeView: View {
    @Environment(SettingsState.self) var settings
    @AppStorage("isListView") private var isListView: Bool = true
    @State private var state = EarthquakesState()
    @State private var isInitialLoad = true

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            VStack(spacing: 0) {
                if isListView {
                    FilterBarView()
                        .background(.bar)
                    Divider()
                }
                Group {
                    if isListView {
                        EarthquakeListView(state: state)
                    } else {
                        EarthquakesMapView(state: state)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isListView)
            }
            .overlay(alignment: .center) {
                if state.isLoading {
                    LoadingIndicator()
                }
            }
            .onAppear {
                if isInitialLoad {
                    state.fetchEarthquakes(startTime: settings.dateStart, endTime: settings.dateEnd)
                    isInitialLoad = false
                }
            }
            .onChange(of: settings.dateRangeDays) {
                state.fetchEarthquakes(startTime: settings.dateStart, endTime: settings.dateEnd)
            }
            .navigationTitle("Earthquakes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("View", selection: $isListView) {
                        Text("List").tag(true)
                        Text("Map").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        settings.isPresented.toggle()
                    } label: {
                        Image(systemName: "bell")
                    }
                }
            }
            .sheet(isPresented: $settings.isPresented) {
                SettingsView()
            }
            .alert("Error", isPresented: Binding(
                get: { state.error != nil },
                set: { if !$0 { state.error = nil } }
            )) {
                Button("Retry") {
                    state.fetchEarthquakes(startTime: settings.dateStart, endTime: settings.dateEnd)
                }
                Button("Cancel", role: .cancel) {
                    state.error = nil
                }
            } message: {
                Text(state.error?.localizedDescription ?? "")
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(SettingsState())
}
