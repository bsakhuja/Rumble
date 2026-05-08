## 1. Project Configuration

- [x] 1.1 Set `IPHONEOS_DEPLOYMENT_TARGET = 26.0` in `Rumble.xcodeproj/project.pbxproj` for Debug and Release configurations
- [x] 1.2 Enable Swift 6 language mode (`SWIFT_STRICT_CONCURRENCY = complete`) in build settings
- [x] 1.3 Add `BGTaskSchedulerPermittedIdentifiers` key to `Info.plist` with value `["com.rumble.earthquake-check"]`
- [x] 1.4 Add `fetch` to `UIBackgroundModes` in `Info.plist`
- [x] 1.5 Add `NSLocationWhenInUseUsageDescription` to `Info.plist` if not already present

## 2. @Observable State Migration

- [x] 2.1 Migrate `SettingsState` to `@Observable`: remove `ObservableObject` conformance, `@Published` wrappers, and `import Combine`; annotate class with `@MainActor`
- [x] 2.2 Migrate `EarthquakesState` to `@Observable`: same cleanup as above; add `error: Error?` property; annotate with `@MainActor`
- [x] 2.3 Migrate `LocationState` to `@Observable`: extract `CLLocationManagerDelegate` into a private inner class `LocationDelegate`; remove `NSObject` superclass from `LocationState`
- [x] 2.4 Update `RumbleApp.swift`: change `@StateObject` to `@State` for `SettingsState`; replace `.environmentObject()` with `.environment()`
- [x] 2.5 Update `HomeView.swift`: change `@StateObject` to `@State` for `EarthquakesState`; change `@EnvironmentObject` to `@Environment(SettingsState.self)`
- [x] 2.6 Update `EarthquakeListView.swift`: replace `@EnvironmentObject var settings: SettingsState` with `@Environment(SettingsState.self) var settings`
- [x] 2.7 Update `EarthquakesMapView.swift`, `EarthquakeDetailView.swift`, `SettingsView.swift`, `EarthquakePreviewView.swift`: same `@Environment` migration
- [x] 2.8 Build and resolve all Swift 6 concurrency warnings (Sendable, actor isolation, etc.)

## 3. Async/Await Network Layer

- [x] 3.1 Rewrite `EarthquakeServiceProtocol` to declare `func getEarthquakes(startTime: Date, endTime: Date) async throws -> GeoJSON`
- [x] 3.2 Rewrite `URLSessionAPIClient` (or replace with a simpler `NetworkClient` struct): use `URLSession.data(for:)` with `async/await`, validate HTTP status (200–299), decode JSON
- [x] 3.3 Remove `Authorization: Bearer TOKEN` header from `EarthquakeEndpoint.headers`
- [x] 3.4 Add retry logic: wrap network call in a loop (max 2 retries) with `Task.sleep` delays of 0.5s and 1.0s for `URLError` failures
- [x] 3.5 Configure `URLCache.shared` with 10MB memory / 50MB disk in `RumbleApp.init()`; set `cachePolicy: .returnCacheDataElseLoad` on `EarthquakeEndpoint` URL requests
- [x] 3.6 Rewrite `EarthquakesState.fetchEarthquakes()` as `async` function using `Task { try await ... }`; catch errors into `self.error`; clear `error` at start of each fetch
- [x] 3.7 Remove all `AnyCancellable` and Combine publisher code from `EarthquakesState`
- [x] 3.8 Add `.refreshable { await state.fetchEarthquakes(...) }` modifier to `EarthquakeListView`'s list
- [x] 3.9 Add `.alert` in `EarthquakeListView` bound to `state.error` with a "Retry" button that calls `fetchEarthquakes()`

## 4. Filter Persistence

- [x] 4.1 Add `RawRepresentable` (String) conformance to `SortMethod` enum in `SettingsView.swift`
- [x] 4.2 Replace `@Published var magnitudeLower: Int` with `@ObservationIgnored @AppStorage("magnitudeLower") var magnitudeLower: Int = 0` in `SettingsState`
- [x] 4.3 Replace `@Published var magnitudeUpper: Int` with `@ObservationIgnored @AppStorage("magnitudeUpper") var magnitudeUpper: Int = 10`
- [x] 4.4 Replace `@Published var sortMethod` with `@ObservationIgnored @AppStorage("sortMethod") var sortMethodRaw: String = SortMethod.none.rawValue`; add computed `var sortMethod: SortMethod` that converts from raw value
- [x] 4.5 Replace `@Published var isListView: Bool` with `@ObservationIgnored @AppStorage("isListView") var isListView: Bool = true`
- [x] 4.6 Replace `dateStart`/`dateEnd` with `@ObservationIgnored @AppStorage("dateRangeDays") var dateRangeDays: Int = 1`; add computed `var dateStart: Date` and `var dateEnd: Date` from offset
- [x] 4.7 Add `@ObservationIgnored @AppStorage("notificationMinMagnitude") var notificationMinMagnitude: Double = 5.0` to `SettingsState`
- [x] 4.8 Update `SettingsView` date pickers to bind to `dateRangeDays` offset picker instead of absolute date pickers (or keep date pickers and compute offset on change)

## 5. Liquid Glass UI

- [x] 5.1 Remove custom `Assets.xcassets` color sets (Almond, Feldgrau, RifleGreen, Xanadu, Text, FloatingButtonForeground) — replace all usages with system colors
- [x] 5.2 Add `magnitudeColor(for magnitude: Double) -> Color` extension on `Color` (or static helper) implementing the 5-tier color system
- [x] 5.3 Update `EarthquakeRow`: apply magnitude color to badge; apply `.glassEffect(.regular, in: .rect(cornerRadius: 16))` to row container
- [x] 5.4 Update `EarthquakePreviewView`: apply `.glassEffect(.regular, in: .rect(cornerRadius: 16))` to card container; use magnitude color on badge
- [x] 5.5 Update `FloatingButtonView`: replace `shadow + background(Color.accentColor)` with `glassEffect` on the button container
- [x] 5.6 Update `LoadingIndicator`: replace `RoundedRectangle + gray` with `.glassEffect` container
- [x] 5.7 Add `.toolbarBackground(.glass)` to `NavigationStack` in `EarthquakeListView` — N/A: iOS 26 applies glass to nav bars automatically
- [x] 5.8 Update `EarthquakeDetailView`: apply magnitude color system to the magnitude display; verify glass/material appearance on List rows
- [x] 5.9 Verify UI in both light and dark mode in Simulator

## 6. Earthquake Notifications

- [x] 6.1 Create `NotificationManager.swift`: singleton (or struct with static methods) wrapping `UNUserNotificationCenter`; methods: `requestPermission()`, `scheduleNotification(for earthquake: Earthquake)`, `pruneOldNotifiedIDs()`
- [x] 6.2 Implement `requestPermission()`: request `.alert`, `.sound`, `.badge`; store result; call once on first launch (gate with `@AppStorage("didRequestNotificationPermission")`)
- [x] 6.3 Implement notification deduplication: read/write `[String]` from `UserDefaults["notifiedEarthquakeIDs"]`; prune IDs where corresponding quake time > 48 hours old
- [x] 6.4 Implement `scheduleNotification(for:)`: build `UNMutableNotificationContent` with title "M[mag] Earthquake", body including place and relative time; add earthquake ID to notified set
- [x] 6.5 Register `BGTaskScheduler` handler for `"com.rumble.earthquake-check"` in `RumbleApp` init or `AppDelegate`
- [x] 6.6 Implement background task handler: fetch last hour of quakes; filter by `notificationMinMagnitude`; fire notifications for new ones; reschedule task; call `task.setTaskCompleted(success:)`
- [x] 6.7 Add `scheduleBackgroundRefresh()` helper that submits `BGAppRefreshTaskRequest` with `earliestBeginDate` of 1 hour from now; call on `scenePhase == .background`
- [x] 6.8 Add Notifications section to `SettingsView`: enable/disable toggle (bound to `@AppStorage("notificationsEnabled")`), magnitude threshold picker, and "Open Settings" link if permission denied
- [ ] 6.9 Test notification flow in Simulator using `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.rumble.earthquake-check"]` in debugger

## 7. Enhanced Search

- [x] 7.1 Change `.contains(searchText)` to `.localizedCaseInsensitiveContains(searchText)` in `EarthquakeListView.searchResults`
- [x] 7.2 Add `SearchScope` enum (`.all`, `.nearby`) to `EarthquakeListView`; add `@State var selectedScope: SearchScope = .all`
- [x] 7.3 Add `.searchScopes($selectedScope)` modifier to the searchable list; implement scope-based filtering in `searchResults` (distance < 500km for `.nearby` when location available)
- [x] 7.4 Add `@ObservationIgnored @AppStorage("recentSearches") var recentSearchesJSON: String = "[]"` to `SettingsState` (or as local `@AppStorage` in the view); implement encode/decode helpers
- [x] 7.5 Implement recent search management: on search commit, prepend query to list; deduplicate; cap at 5; save back to `@AppStorage`
- [x] 7.6 Add `.searchSuggestions()` modifier showing recent searches when query is empty; tapping a suggestion sets `searchText`
- [x] 7.7 Add empty-state view in `EarthquakeListView`: show when `searchResults.isEmpty`; display context-aware message ("No earthquakes matching..." vs. "No earthquakes in this time range")
- [x] 7.8 Add "Clear Search" and "Change Dates" recovery buttons in empty-state view

## 8. Verification

- [x] 8.1 Build succeeds with zero warnings in Release configuration
- [x] 8.2 Run `RumbleTests` unit tests — all pass (decoder tests still valid)
- [x] 8.3 Launch app in Simulator on iOS 26: verify Liquid Glass appears on rows, FAB, and navigation bar
- [x] 8.4 Set magnitude filter to 3–5, quit app, relaunch — verify filter is restored
- [x] 8.5 Change sort to "Magnitude Descending", quit, relaunch — verify sort is restored
- [x] 8.6 Pull down on earthquake list — verify refresh spinner appears and new data loads
- [x] 8.7 Disable network (Simulator > Network Link Conditioner > 100% Loss) — verify error alert appears with Retry button
- [x] 8.8 Search "san jose" — verify case-insensitive results appear
- [x] 8.9 Perform 6 searches — verify only last 5 appear as suggestions
- [ ] 8.10 Simulate background task in debugger — verify notification fires for M5.0+ quakes
