## ADDED Requirements

### Requirement: Notification permission requested on first launch
The app SHALL request `UNAuthorizationOptions([.alert, .sound, .badge])` on first launch via a contextual prompt. The request SHALL occur after the user has seen the main screen (not on cold launch).

#### Scenario: Permission prompt shown once
- **WHEN** the app is launched for the first time and the user has viewed the main list
- **THEN** the system notification permission dialog is presented exactly once

#### Scenario: Permission not re-requested
- **WHEN** the user has previously granted or denied notification permission
- **THEN** no permission dialog is shown

### Requirement: Info.plist declares background fetch capability
The app's `Info.plist` SHALL include `BGTaskSchedulerPermittedIdentifiers` containing `"com.rumble.earthquake-check"`. The `UIBackgroundModes` array SHALL include `"fetch"`.

#### Scenario: Background task identifier registered
- **WHEN** the app registers background tasks at launch
- **THEN** `BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.rumble.earthquake-check", ...)` succeeds without error

### Requirement: Background task fetches recent earthquakes
The `BGAppRefreshTask` handler SHALL fetch earthquakes for the last hour from the USGS API and fire local notifications for any M5.0+ (or above `notificationMinMagnitude`) earthquakes not previously notified.

#### Scenario: Notification fired for significant quake
- **WHEN** the background task runs and a new M5.0+ earthquake is found
- **THEN** a `UNNotificationRequest` is scheduled with the earthquake's magnitude, place, and time in the notification body

#### Scenario: No duplicate notifications
- **WHEN** the background task runs and an earthquake was already notified
- **THEN** no second notification is fired for that earthquake ID

#### Scenario: Background task rescheduled
- **WHEN** the background task handler completes
- **THEN** a new `BGAppRefreshTask` is submitted to run within the next hour

### Requirement: Notified earthquake IDs deduplicated
The set of already-notified earthquake IDs SHALL be persisted in `UserDefaults` under key `"notifiedEarthquakeIDs"` as a `[String]`. Entries older than 48 hours SHALL be pruned on each background wake.

#### Scenario: ID stored after notification
- **WHEN** a notification is fired for earthquake with id "nc73649170"
- **THEN** "nc73649170" is added to `UserDefaults["notifiedEarthquakeIDs"]`

#### Scenario: Old IDs pruned
- **WHEN** the background task runs and some stored IDs correspond to earthquakes older than 48 hours
- **THEN** those IDs are removed from the stored set

### Requirement: Notification content includes key earthquake details
Each notification SHALL include: magnitude (formatted to 1 decimal), place string, and relative time ("5 minutes ago") in the body. The notification title SHALL be "M[magnitude] Earthquake".

#### Scenario: Notification title format
- **WHEN** a notification is created for a M6.2 earthquake
- **THEN** the notification title is "M6.2 Earthquake"

#### Scenario: Notification body includes place
- **WHEN** a notification is created for an earthquake near "20km NE of San Jose, CA"
- **THEN** the notification body includes "20km NE of San Jose, CA"

### Requirement: Notification settings shown in SettingsView
`SettingsView` SHALL include a section for notification preferences: toggle to enable/disable notifications, magnitude threshold picker (3.0–8.0 in 0.5 increments), and a system link to open iOS notification settings if permission was denied.

#### Scenario: Notification toggle visible
- **WHEN** the user opens SettingsView
- **THEN** a "Notifications" section is visible with an enable/disable toggle

#### Scenario: Denied permission shows system settings link
- **WHEN** notification permission is denied and the user enables the toggle
- **THEN** a button to open iOS Settings is shown
