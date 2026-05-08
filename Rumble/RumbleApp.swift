//
//  RumbleApp.swift
//  Rumble
//
//  Created by Brian Sakhuja on 11/7/23.
//

import SwiftUI
import BackgroundTasks

@main
struct RumbleApp: App {
    @State private var settings = SettingsState()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        URLCache.shared = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.rumble.earthquake-check", using: nil) { task in
            NotificationManager.shared.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(settings)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                NotificationManager.shared.scheduleBackgroundRefresh()
            }
        }
    }
}
