## ADDED Requirements

### Requirement: State classes use @Observable macro
All state classes (`EarthquakesState`, `SettingsState`, `LocationState`) SHALL use the `@Observable` macro instead of `ObservableObject`. No `@Published` wrappers SHALL remain. Combine framework SHALL NOT be imported in state files.

#### Scenario: Fine-grained view updates
- **WHEN** a property in `SettingsState` changes
- **THEN** only views that read that specific property re-render; unrelated views do not re-render

#### Scenario: No Combine dependency in state
- **WHEN** the state files are compiled
- **THEN** no `import Combine` statement exists in `EarthquakesState.swift`, `SettingsState.swift`, or `LocationState.swift`

### Requirement: View property wrappers updated for @Observable
Views SHALL use `@State` (for owned state) and `@Environment` (for injected state) instead of `@StateObject` and `@EnvironmentObject`. The `RumbleApp` entry point SHALL use `.environment(settingsState)` instead of `.environmentObject(settingsState)`.

#### Scenario: EarthquakesState ownership
- **WHEN** `HomeView` is initialized
- **THEN** `EarthquakesState` is declared as `@State private var state = EarthquakesState()`, not `@StateObject`

#### Scenario: SettingsState injection
- **WHEN** `RumbleApp` creates the root view
- **THEN** `SettingsState` is passed via `.environment(settingsState)` and consumed in child views via `@Environment(SettingsState.self) var settings`

### Requirement: Swift 6 strict concurrency compliance
All state classes and networking code SHALL compile without warnings under Swift 6 strict concurrency. `@Observable` classes that mutate UI state SHALL be annotated with `@MainActor`.

#### Scenario: No data race warnings
- **WHEN** the project is compiled with `SWIFT_STRICT_CONCURRENCY = complete`
- **THEN** zero concurrency warnings are emitted

#### Scenario: Main actor isolation for UI state
- **WHEN** `EarthquakesState` is declared
- **THEN** the class is annotated with `@MainActor` to ensure all property mutations occur on the main thread

### Requirement: LocationState integrates with @Observable pattern
`LocationState` SHALL be refactored from `NSObject + CLLocationManagerDelegate + ObservableObject` to an `@Observable` class that wraps a separate `CLLocationManager` delegate object.

#### Scenario: Location authorization publishes correctly
- **WHEN** the user grants location authorization
- **THEN** `LocationState.authorizationStatus` updates and any view reading it re-renders

#### Scenario: Delegate separation
- **WHEN** `LocationState` is implemented
- **THEN** `CLLocationManagerDelegate` is implemented by a separate private class or struct, not by `LocationState` itself, to avoid `NSObject` subclassing requirement
