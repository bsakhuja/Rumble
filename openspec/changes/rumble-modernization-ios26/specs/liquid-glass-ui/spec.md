## ADDED Requirements

### Requirement: Glass effect on cards and list rows
`EarthquakeRow` and `EarthquakePreviewView` SHALL apply `.glassEffect(.regular, in: .rect(cornerRadius: 16))` to their container. The background SHALL be translucent glass, not an opaque color.

#### Scenario: List row glass appearance
- **WHEN** the earthquake list is displayed
- **THEN** each row has a glass-effect background with rounded corners

#### Scenario: Map preview glass appearance
- **WHEN** a user taps an earthquake marker on the map
- **THEN** the bottom-sheet preview card renders with a glass effect

### Requirement: Glass effect on navigation and toolbars
The `NavigationStack` in `EarthquakeListView` SHALL use `.toolbarBackground(.glass)`. The settings sheet SHALL use a glass-effect header.

#### Scenario: Navigation bar glass
- **WHEN** the earthquake list is shown
- **THEN** the navigation bar background is glass (translucent), not opaque

#### Scenario: Toolbar glass
- **WHEN** the search bar and filter button are visible in the toolbar
- **THEN** the toolbar background applies the glass effect

### Requirement: FloatingButtonView uses glass effect
`FloatingButtonView` SHALL replace its manual `shadow + background(Color.accentColor)` implementation with `glassEffect` and a system tint overlay.

#### Scenario: FAB glass appearance
- **WHEN** the floating action button is visible
- **THEN** it displays a glass-effect circular button with a system-tinted icon

### Requirement: Magnitude-based color coding
Earthquake magnitude SHALL be visually encoded with a color system using Apple system colors. The color SHALL be applied to the magnitude badge in `EarthquakeRow` and `EarthquakeDetailView`.

#### Scenario: Minor earthquake color
- **WHEN** an earthquake has magnitude < 2.0
- **THEN** the magnitude badge uses `.systemGray`

#### Scenario: Light earthquake color
- **WHEN** an earthquake has magnitude between 2.0 and 3.9
- **THEN** the magnitude badge uses `.systemYellow`

#### Scenario: Moderate earthquake color
- **WHEN** an earthquake has magnitude between 4.0 and 4.9
- **THEN** the magnitude badge uses `.systemOrange`

#### Scenario: Strong earthquake color
- **WHEN** an earthquake has magnitude between 5.0 and 6.9
- **THEN** the magnitude badge uses `.systemRed`

#### Scenario: Major/great earthquake color
- **WHEN** an earthquake has magnitude 7.0 or greater
- **THEN** the magnitude badge uses `.systemPurple`

### Requirement: LoadingIndicator uses glass effect
`LoadingIndicator` SHALL replace its `RoundedRectangle + gray foreground` implementation with a glass-effect container.

#### Scenario: Loading overlay glass
- **WHEN** earthquake data is being fetched
- **THEN** the loading indicator overlays the content with a glass-effect card containing a spinner

### Requirement: Minimum deployment target is iOS 26
The project's `IPHONEOS_DEPLOYMENT_TARGET` SHALL be set to `26.0` in all build configurations. All iOS 26 API usage (glassEffect, etc.) SHALL be called without `@available` guards.

#### Scenario: Deployment target in project file
- **WHEN** `project.pbxproj` is read
- **THEN** `IPHONEOS_DEPLOYMENT_TARGET = 26.0` appears in Debug, Release, and all scheme configurations

#### Scenario: No availability guards for iOS 26 APIs
- **WHEN** `glassEffect()` or other iOS 26 APIs are used
- **THEN** no `if #available(iOS 26, *)` guards wrap these calls
