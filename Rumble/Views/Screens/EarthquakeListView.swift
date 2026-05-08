//
//  EarthquakeListView.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/21/23.
//

import SwiftUI

struct EarthquakeListView: View {
    @State private var isInitialLoad: Bool = true
    @State private var searchText = ""
    @ObservedObject var state: EarthquakesState
    @EnvironmentObject var settings: SettingsState
    
    var filteredEarthquakes: [Earthquake]? {
        let filtered = state.earthquakes?.filter {
            $0.properties.magnitude < Double(settings.magnitudeUpper) &&
            $0.properties.magnitude > Double(settings.magnitudeLower)
        }
        switch settings.sortMethod {
        case .none:
            return filtered
        case .locationAscending:
            if let userLocation = settings.userLocation {
                return filtered?.sorted(by: { lhs, rhs in
                    lhs.geometry.clLocation.distance(from: userLocation) < rhs.geometry.clLocation.distance(from: userLocation)
                })
            } else {
                return filtered
            }
            
        case .locationDescending:
            if let userLocation = settings.userLocation {
                return filtered?.sorted(by: { lhs, rhs in
                    lhs.geometry.clLocation.distance(from: userLocation) > rhs.geometry.clLocation.distance(from: userLocation)
                })
            } else {
                return filtered
            }
        case .magnitudeAscending:
            return filtered?.sorted(by: { lhs, rhs in
                lhs.properties.magnitude < rhs.properties.magnitude
            })
        case .magnitudeDescending:
            return filtered?.sorted(by: { lhs, rhs in
                lhs.properties.magnitude > rhs.properties.magnitude
            })
        case .timeAscending:
            return filtered?.sorted(by: { lhs, rhs in
                lhs.properties.time < rhs.properties.time
            })
        case .timeDescending:
            return filtered?.sorted(by: { lhs, rhs in
                lhs.properties.time > rhs.properties.time
            })
        }
        
    }
    
    var searchResults: [Earthquake]? {
        if searchText.isEmpty {
            return filteredEarthquakes
        } else {
            return filteredEarthquakes?.filter {
                $0.properties.place?.contains(searchText) ?? false
            }
        }
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                Group {
                    if let earthquakes = searchResults, !earthquakes.isEmpty {
                        ScrollView {
                            LazyVStack {
                                ForEach(earthquakes, id: \.self) { earthquake in
                                    NavigationLink {
                                        EarthquakeDetailView(earthquake: earthquake)
                                            .onAppear {
                                                state.shouldShowFloatingButton = false
                                            }
                                    } label: {
                                        EarthquakeRow(earthquake: earthquake)
                                            .padding(.horizontal, 16.0)
                                    }
                                }
                            }
                        }
                        
                    } else {
                        Text("No earthquakes to show").font(.title)
                        Text("Try adjusting your search settings or query").font(.subheadline)
                        Spacer()
                    }
                }
                .onAppear {
                    state.shouldShowFloatingButton = true
                    
                    if isInitialLoad {
                        state.fetchEarthquakes(startTime: settings.dateStart, endTime: settings.dateEnd)
                        isInitialLoad = false
                    }
                }
                .onChange(of: settings.dateStart) {
                    state.fetchEarthquakes(startTime: settings.dateStart, endTime: settings.dateEnd)
                }
                .onChange(of: settings.dateEnd) {
                    state.fetchEarthquakes(startTime: settings.dateStart, endTime: settings.dateEnd)
                }
                .navigationTitle("Earthquakes")
                .toolbar {
                    Button {
                        settings.isPresented.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                .sheet(isPresented: $settings.isPresented) {
                    SettingsView(state: settings)
                }
                
            }
            .searchable(text: $searchText)
//                ForEach(searchResults, id: \.self) { result in
//                                Text("Are you looking for \(result)?").searchCompletion(result)
//                            }
//                        }
            .opacity(state.isLoading ? 0.5 : 1)
            
            LoadingIndicator()
                .opacity(state.isLoading ? 1 : 0)
        }
        
    }
}

#Preview("Default") {
    EarthquakeListView(state: .previewStateDefault)
        .environmentObject(SettingsState())
}

#Preview("Loading") {
    EarthquakeListView(state: .previewStateLoading)
        .environmentObject(SettingsState())
}
