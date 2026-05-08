//
//  NotificationManager.swift
//  Rumble
//

import Foundation
import UserNotifications
import BackgroundTasks

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let taskIdentifier = "com.rumble.earthquake-check"
    private let notifiedIDsKey = "notifiedEarthquakeIDs"
    private let permissionRequestedKey = "didRequestNotificationPermission"

    // MARK: - Permission

    func requestPermissionIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: permissionRequestedKey) else { return }
        Task {
            _ = await requestPermission()
            UserDefaults.standard.set(true, forKey: permissionRequestedKey)
        }
    }

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Background Refresh

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()

        let fetchTask = Task {
            do {
                let service = EarthquakeService()
                let endTime = Date()
                let startTime = endTime.addingTimeInterval(-3600)
                let geoJSON = try await service.getEarthquakes(startTime: startTime, endTime: endTime)
                let minMag = UserDefaults.standard.double(forKey: "notificationMinMagnitude")
                let threshold = minMag > 0 ? minMag : 5.0
                pruneOldNotifiedIDs(earthquakes: geoJSON.earthquakes)
                let notifiedIDs = Set(notifiedEarthquakeIDs())
                for quake in geoJSON.earthquakes where quake.properties.magnitude >= threshold {
                    if !notifiedIDs.contains(quake.id) {
                        await scheduleNotification(for: quake)
                    }
                }
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = { fetchTask.cancel() }
    }

    // MARK: - Notification Scheduling

    func scheduleNotification(for earthquake: Earthquake) async {
        let content = UNMutableNotificationContent()
        let mag = preciseRound(earthquake.properties.magnitude, precision: .hundredths)
        content.title = "M\(mag) Earthquake"
        let place = earthquake.properties.place ?? "Unknown location"
        let relativeTime = earthquake.properties.date.formatted(.relative(presentation: .named))
        content.body = "\(place) — \(relativeTime)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: earthquake.id,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
        addNotifiedID(earthquake.id)
    }

    // MARK: - Deduplication

    private func notifiedEarthquakeIDs() -> [String] {
        UserDefaults.standard.stringArray(forKey: notifiedIDsKey) ?? []
    }

    private func addNotifiedID(_ id: String) {
        var ids = notifiedEarthquakeIDs()
        if !ids.contains(id) { ids.append(id) }
        UserDefaults.standard.set(ids, forKey: notifiedIDsKey)
    }

    private func pruneOldNotifiedIDs(earthquakes: [Earthquake]) {
        let cutoff = Date().addingTimeInterval(-48 * 3600)
        let recentIDs = Set(earthquakes.filter { $0.properties.date > cutoff }.map { $0.id })
        let pruned = notifiedEarthquakeIDs().filter { recentIDs.contains($0) }
        UserDefaults.standard.set(pruned, forKey: notifiedIDsKey)
    }
}
