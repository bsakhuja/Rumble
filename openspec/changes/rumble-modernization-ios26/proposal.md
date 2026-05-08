## Why

Rumble was built on iOS 17 patterns and has accumulated technical debt: ObservableObject state causes unnecessary view redraws, filters reset on every launch, there are no notifications for significant events, and the UI predates the Liquid Glass design language introduced in iOS 26. Modernizing the app brings it in line with current Apple platform standards and meaningfully improves the user experience.

## What Changes

- **Replace ObservableObject/Combine with `@Observable` macro** across all state classes (`EarthquakesState`, `SettingsState`, `LocationState`), eliminating Combine publishers and `@Published` wrappers
- **Raise minimum deployment target to iOS 26** and adopt Swift 6 strict concurrency
- **Adopt Liquid Glass design language**: glass-effect navigation bars, toolbars, floating buttons, modal sheets, and magnitude-based color system
- **Modernize the network layer**: replace Combine `AnyPublisher` with `async/await`, add structured error handling with user-visible alerts, add retry logic and response caching
- **Persist user filters across sessions** using `@AppStorage` for all `SettingsState` properties (magnitude range, sort method, view preference, date range offset)
- **Local notifications for significant earthquakes**: background fetch triggers local notifications for M5.0+ earthquakes near the user or globally
- **Improved search settings**: case-insensitive search, search by magnitude range, recent searches, search scope toggle (all regions vs. nearby)
- **Additional improvements**: fix silent error swallowing in `EarthquakesState`, add pull-to-refresh, fix `Authorization: Bearer TOKEN` placeholder header in `EarthquakeEndpoint`, add empty-state views, improve distance calculation accuracy

## Capabilities

### New Capabilities

- `observable-state`: Replace all ObservableObject/Combine state classes with @Observable macro pattern, updating all view property wrappers accordingly
- `liquid-glass-ui`: Adopt iOS 26 Liquid Glass design throughout — navigation, toolbars, sheets, cards, floating button, and magnitude color coding
- `async-network`: Replace Combine-based URLSessionAPIClient with async/await, add error propagation, retry logic, and URLCache integration  
- `filter-persistence`: Persist all SettingsState filter properties across app sessions using @AppStorage
- `earthquake-notifications`: Local notifications for M5.0+ earthquakes via BGAppRefreshTask and UNUserNotificationCenter
- `enhanced-search`: Case-insensitive search, magnitude-range filtering from search bar, recent searches, and search scope (global vs. nearby)

### Modified Capabilities

<!-- No existing specs to modify — this is a greenfield modernization -->

## Impact

- **All state files**: `Rumble/States/EarthquakesState.swift`, `Rumble/States/SettingsState.swift`, `Rumble/States/LocationState.swift`
- **All view files**: `Rumble/HomeView.swift`, `Rumble/Views/Screens/*.swift`, `Rumble/Views/Components/**/*.swift`, `Rumble/RumbleApp.swift`
- **Networking**: `Rumble/Networking/NetworkManager.swift`, `Rumble/Networking/QuakeError.swift`
- **Project config**: `Rumble.xcodeproj/project.pbxproj` (deployment target), `Info.plist` (background modes, notification permission)
- **No external dependencies added** — uses only Apple frameworks (UserNotifications, BackgroundTasks, already-imported MapKit/CoreLocation)
- **Breaking**: Minimum iOS version raised to 26; removes Combine dependency from networking layer
