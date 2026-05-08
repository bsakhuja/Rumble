//
//  SettingsView.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/9/23.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(SettingsState.self) var settings
    @State private var notificationPermissionDenied = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Notify for significant earthquakes", isOn: $settings.notificationsEnabled)
                        .onChange(of: settings.notificationsEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    let granted = await NotificationManager.shared.requestPermission()
                                    if !granted {
                                        settings.notificationsEnabled = false
                                        notificationPermissionDenied = true
                                    }
                                }
                            }
                        }
                    if settings.notificationsEnabled {
                        Picker("Minimum magnitude", selection: $settings.notificationMinMagnitude) {
                            ForEach(stride(from: 3.0, through: 8.0, by: 0.5).map { $0 }, id: \.self) { mag in
                                Text("M\(mag, specifier: "%.1f")+").tag(mag)
                            }
                        }
                    }
                    if notificationPermissionDenied {
                        Button("Open Notification Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundStyle(.blue)
                    }
                }

                Section("About") {
                    Text("Rumble version \(AppVersionProvider.versionAndBuild)")
                    Text("Made by Brian Sakhuja")
                    Text("Earthquake data from USGS")
                }
            }
            .navigationTitle("Settings")
        }
        .task {
            let status = await UNUserNotificationCenter.current().notificationSettings()
            notificationPermissionDenied = status.authorizationStatus == .denied
        }
    }
}

#Preview {
    SettingsView()
        .environment(SettingsState())
}
