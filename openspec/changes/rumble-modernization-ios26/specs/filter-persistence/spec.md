## ADDED Requirements

### Requirement: Magnitude filter persists across sessions
`SettingsState.magnitudeLower` and `SettingsState.magnitudeUpper` SHALL be backed by `@AppStorage` keys `"magnitudeLower"` and `"magnitudeUpper"` with defaults of `0` and `10` respectively.

#### Scenario: Magnitude filter restored after relaunch
- **WHEN** the user sets magnitudeLower to 3 and relaunches the app
- **THEN** `magnitudeLower` is 3 on the next launch without any explicit restore call

#### Scenario: Default values on first launch
- **WHEN** the app is launched for the first time (no stored values)
- **THEN** `magnitudeLower` is 0 and `magnitudeUpper` is 10

### Requirement: Sort method persists across sessions
`SettingsState.sortMethod` SHALL be backed by `@AppStorage` key `"sortMethod"` using `SortMethod`'s raw string value. `SortMethod` SHALL conform to `RawRepresentable` with `RawValue == String`.

#### Scenario: Sort method restored after relaunch
- **WHEN** the user selects `.magnitudeDescending` and relaunches the app
- **THEN** `sortMethod` is `.magnitudeDescending` on the next launch

#### Scenario: Default sort on first launch
- **WHEN** the app is launched for the first time
- **THEN** `sortMethod` is `.none`

### Requirement: View preference (list/map) persists across sessions
`SettingsState.isListView` SHALL be backed by `@AppStorage` key `"isListView"` with a default of `true`.

#### Scenario: Map view preference restored
- **WHEN** the user switches to map view and relaunches the app
- **THEN** the app opens in map view (`isListView == false`)

### Requirement: Date range stored as day offset
The date range SHALL be stored as an integer day offset (`dateRangeDays: Int`) backed by `@AppStorage("dateRangeDays")` with a default of `1` (yesterday to today). The actual `dateStart` and `dateEnd` are computed from this offset relative to the current date at launch.

#### Scenario: Day offset applied on launch
- **WHEN** `dateRangeDays` is 7 and the app launches
- **THEN** `dateStart` is 7 days before today and `dateEnd` is today

#### Scenario: Day offset default
- **WHEN** the app is launched for the first time
- **THEN** `dateRangeDays` is 1 (showing yesterday to today)

### Requirement: Notification magnitude threshold persists
`SettingsState.notificationMinMagnitude` SHALL be backed by `@AppStorage("notificationMinMagnitude")` with a default of `5.0`.

#### Scenario: Threshold persists
- **WHEN** the user changes the notification threshold to 6.0 and relaunches
- **THEN** `notificationMinMagnitude` is 6.0 on the next launch
