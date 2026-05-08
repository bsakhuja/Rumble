# Rumble

iOS app that fetches live earthquake data from the USGS GeoJSON API and displays it in a searchable/filterable list and on a MapKit map.

## Build & Run

Open `Rumble.xcodeproj` in Xcode and run the **Rumble** scheme on an iOS 17+ simulator or device.

```bash
xcodebuild -scheme Rumble -configuration Debug
```

## Testing

```bash
# Unit tests (GeoJSON decoder coverage)
xcodebuild test -scheme Rumble -only-testing:RumbleTests

# UI tests
xcodebuild test -scheme Rumble -only-testing:RumbleUITests
```

## Architecture

MVVM + Combine. No persistence — data is fetched fresh each session.

| Folder | Contents |
|---|---|
| `Rumble/Models/` | `Earthquake`, `EarthquakeProperties`, `EarthquakeGeometry`, `GeoJSON`, `QuakeLocation` |
| `Rumble/Networking/` | `NetworkManager` (URLSession + Combine), `QuakeError`, `APIEndpoint` protocol |
| `Rumble/States/` | `EarthquakesState`, `SettingsState`, `LocationState` — all `ObservableObject` |
| `Rumble/Views/Screens/` | `HomeView`, `EarthquakeListView`, `EarthquakesMapView`, `EarthquakeDetailView`, `SettingsView` |
| `Rumble/Views/Components/` | `EarthquakeRow`, `EarthquakePreviewView`, `FloatingButtonView`, `LoadingIndicator` |
| `Rumble/Utilities/` | `Round`, date/location extensions |

## Key Files

- **Entry point**: `Rumble/RumbleApp.swift`
- **Main screen**: `Rumble/HomeView.swift` — owns `EarthquakesState` (`@StateObject`) and injects `SettingsState` + `LocationState` as environment objects
- **Network layer**: `Rumble/Networking/NetworkManager.swift` — `URLSessionAPIClient<EarthquakeEndpoint>`, Combine publishers
- **API endpoint**: `EarthquakeEndpoint` enum covers USGS query parameters (starttime, endtime, minmagnitude, etc.)
- **State**: `EarthquakesState` drives loading/error/data; `SettingsState` holds filter/sort preferences; `LocationState` wraps `CLLocationManager`

## Conventions

- SwiftUI only — no UIKit except `LaunchScreen.storyboard`
- All views include `#Preview` macros
- Networking is protocol-driven (`APIClient`, `EarthquakeServiceProtocol`) for testability
- Combine is used for async work — no `async/await` in the networking layer
- Sorting via `SortMethod` enum (7 cases) defined in `SettingsView.swift`
- Custom color palette defined in `Assets.xcassets`: `Almond`, `Feldgrau`, `RifleGreen`, `Xanadu`
- Bundle ID: `com.bsakhuja.Rumble` · Min iOS: 17.0
