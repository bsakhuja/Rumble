## Context

Rumble is a SwiftUI earthquake-tracking app (~18 source files) that calls the public USGS GeoJSON API. It was built against iOS 17 with ObservableObject + Combine for all state management. The app has no persistence, no notifications, a broken Authorization header in its API client, and a UI that predates iOS 26's Liquid Glass design language.

Current state summary:
- `EarthquakesState`, `SettingsState`, `LocationState` — all `ObservableObject` classes with `@Published` + Combine
- `URLSessionAPIClient` returns `AnyPublisher<T, Error>`; errors are silently swallowed in `receiveCompletion`
- `EarthquakeEndpoint` includes `Authorization: Bearer TOKEN` header on a public API
- All settings reset on launch; no `UserDefaults`/`@AppStorage` usage anywhere
- No `UNUserNotificationCenter`, no `BackgroundTasks` framework usage
- Search is case-sensitive `.contains()` on `place` field only

## Goals / Non-Goals

**Goals:**
- Migrate all state to `@Observable` (Swift 5.9+ / iOS 17+ macro, fully supported on iOS 26)
- Raise deployment target to iOS 26, adopt Swift 6 strict concurrency (`Sendable`, `@MainActor`)
- Adopt Liquid Glass throughout: `glassEffect()` on cards and sheets, `.glassEffect()` on toolbars/nav bars, magnitude-based accent color system
- Replace Combine networking with `async/await`; surface errors to users
- Persist all filter settings via `@AppStorage`
- Schedule background refresh and fire local notifications for M5.0+ quakes
- Improve search: case-insensitive, scope toggle, recent queries stored in `@AppStorage`

**Non-Goals:**
- Remote push notifications (requires server-side infrastructure)
- iCloud sync of settings
- Widget or Live Activity support
- Offline caching of earthquake data beyond URLCache
- Changing the data source (USGS API stays)

## Decisions

### 1. `@Observable` over `ObservableObject`

**Decision:** Migrate all three state classes to the `@Observable` macro.

**Rationale:** `@Observable` performs fine-grained dependency tracking — only the properties a view actually reads trigger redraws. The existing `@Published`-on-everything pattern causes entire view trees to re-render on any change. With `@Observable`, views drop `@ObservedObject`/`@EnvironmentObject` in favor of direct `@State`/`@Environment` injection.

**Migration pattern:**
```swift
// Before
class SettingsState: ObservableObject {
    @Published var magnitudeLower: Int = 0
}
// After
@Observable class SettingsState {
    var magnitudeLower: Int = 0
}
```

Views change: `@StateObject` → `@State`, `@EnvironmentObject` → `@Environment`, remove `.environmentObject()` in favor of `.environment()`.

**Alternative considered:** Keep ObservableObject — rejected because it causes unnecessary redraws and doesn't support Swift 6 `Sendable` cleanly.

### 2. `async/await` over Combine in networking

**Decision:** Replace `AnyPublisher<GeoJSON, Error>` with `async throws -> GeoJSON`.

**Rationale:** Combine adds complexity (subscription management, type-erasure) for a single-shot network call. `async/await` with `URLSession.data(for:)` is simpler, integrates cleanly with Swift 6 concurrency, and makes error propagation straightforward. The Combine publisher chain was also the source of the silent error-swallowing bug.

**New shape:**
```swift
protocol EarthquakeServiceProtocol {
    func getEarthquakes(startTime: Date, endTime: Date) async throws -> GeoJSON
}
```

`EarthquakesState.fetchEarthquakes()` becomes an `async` method called via `Task { }` in `.task {}` modifiers. Errors are caught and stored in an `@Observable` `error: Error?` property, rendered as an `.alert`.

**Retry logic:** 2 automatic retries with exponential backoff (0.5s, 1s) for `URLError` network errors only.

**Caching:** Configure `URLCache.shared` with 10MB memory / 50MB disk. Set `cachePolicy: .returnCacheDataElseLoad` on requests so the list populates instantly from cache while a fresh fetch runs.

**Fix:** Remove `Authorization: Bearer TOKEN` from `EarthquakeEndpoint` headers — the USGS API is public and doesn't require authentication. This header currently causes no harm (the server ignores it) but is confusing and misleading.

### 3. `@AppStorage` for filter persistence

**Decision:** Replace `@Published var` with `@AppStorage` directly on `@Observable` class properties (iOS 17.1+ pattern using `@ObservationIgnored @AppStorage`).

```swift
@Observable class SettingsState {
    @ObservationIgnored @AppStorage("magnitudeLower") var magnitudeLower: Int = 0
    @ObservationIgnored @AppStorage("magnitudeUpper") var magnitudeUpper: Int = 10
    @ObservationIgnored @AppStorage("sortMethod") var sortMethodRaw: String = SortMethod.none.rawValue
}
```

`SortMethod` gains `RawRepresentable` (String) conformance for `@AppStorage` compatibility. Date range is stored as a day-offset integer (e.g., `dateRangeOffsetDays: Int = 1`) rather than an absolute Date, so defaults stay meaningful across sessions.

**Alternative considered:** `Codable` struct serialized to UserDefaults as Data — overkill for simple scalar settings.

### 4. Local notifications via BGAppRefreshTask

**Decision:** Register a `BGAppRefreshTask` identifier (`com.rumble.earthquake-check`) and schedule it in `applicationDidEnterBackground`. On wake, fetch quakes for the last hour; fire `UNNotificationRequest` for any M5.0+ earthquakes not previously notified.

**Deduplication:** Store the set of already-notified earthquake IDs in `UserDefaults` (keyed `notifiedEarthquakeIDs`, `[String]`). Clear entries older than 48 hours.

**Permission flow:** Request `UNAuthorizationOptions([.alert, .sound, .badge])` on first app launch, gated behind a contextual prompt ("Get notified about major earthquakes").

**Threshold:** M5.0+ is configurable in `SettingsState` (`notificationMinMagnitude: Double = 5.0`), persisted via `@AppStorage`.

**Alternative considered:** Silent push notifications — rejected (requires server infrastructure).

### 5. Liquid Glass UI adoption

**Decision:** Use iOS 26's `glassEffect()` view modifier on cards, sheets, and the floating action button. Apply `.glassEffect(.regular, in: .rect(cornerRadius: 16))` to `EarthquakeRow`, `EarthquakePreviewView`, and `LoadingIndicator`. Use `.toolbarBackground(.glass)` on `NavigationStack`. Update `FloatingButtonView` to use `glassEffect` instead of manual shadow/background.

**Magnitude color system:**
| Range | Color token |
|-------|-------------|
| < 2.0 | `.systemGray` |
| 2.0–3.9 | `.systemYellow` |
| 4.0–4.9 | `.systemOrange` |
| 5.0–6.9 | `.systemRed` |
| 7.0+ | `.systemPurple` |

Use `Color(uiColor: .systemRed)` etc. for automatic dark/light adaptation. Remove the custom `.xcassets` color set (Almond, Feldgrau, etc.) since Liquid Glass uses system tints.

**Alternative considered:** Keep existing color set and overlay glass — rejected because custom opaque colors conflict with glass translucency.

### 6. Enhanced search

**Decision:** 
- Change `.contains()` to `.localizedCaseInsensitiveContains()` — one-line fix
- Add scope: `SearchScope` enum (`.all`, `.nearby`) using `.searchScopes()` modifier
- Persist last 5 search terms in `@AppStorage("recentSearches")` as `[String]` (JSON-encoded)
- Show recent searches in search suggestions via `.searchSuggestions()` modifier

## Risks / Trade-offs

- **BGAppRefreshTask scheduling is not guaranteed** → Mitigation: Also check for new quakes on foreground return via `.scenePhase` `.onChange` so users at least see fresh data when they open the app
- **`@ObservationIgnored @AppStorage` is a workaround** for combining `@Observable` with `@AppStorage` → Mitigation: Pattern is documented in Apple's migration guide; if it changes, localized to `SettingsState` only
- **Removing the custom color palette** changes the app's visual identity → Accept: Liquid Glass system colors look better and adapt to user accent color preferences
- **iOS 26 deployment target** means no iOS 24/25 support → Accept: User explicitly requested this
- **Background fetch is unreliable on battery-optimized devices** → Mitigation: Inform users in notification settings UI that delivery timing varies

## Migration Plan

1. Bump deployment target in `project.pbxproj` to iOS 26; enable Swift 6 language mode
2. Migrate state classes to `@Observable` one at a time (SettingsState → LocationState → EarthquakesState)
3. Update all view property wrappers and `.environment()` injection sites
4. Rewrite `NetworkManager.swift` — new `async/await` client, remove Combine
5. Add `@AppStorage` persistence to SettingsState
6. Add notification infrastructure (`NotificationManager.swift`, Info.plist keys, background modes)
7. Apply Liquid Glass UI pass across all views
8. Enhance search implementation
9. Add empty state views and error alert handling

**Rollback:** Each step is independently mergeable; Git history allows reverting any layer.

## Open Questions

- Should the notification threshold (M5.0) also filter by proximity to user? (e.g., M4.0+ within 100km OR M5.0+ anywhere) — recommend yes, but needs user research
- Should date range persist as a fixed offset ("last N days") or as absolute start/end dates? — recommend offset for freshness
