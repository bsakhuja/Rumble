## ADDED Requirements

### Requirement: Case-insensitive text search
The `searchResults` computed property in `EarthquakeListView` SHALL use `.localizedCaseInsensitiveContains()` instead of `.contains()` when matching earthquake place names.

#### Scenario: Case-insensitive match
- **WHEN** the user types "san jose" in the search bar
- **THEN** earthquakes with place containing "San Jose" or "SAN JOSE" are returned

#### Scenario: Empty search returns all filtered results
- **WHEN** the search text is empty
- **THEN** `searchResults` returns all magnitude-filtered earthquakes without text filtering

### Requirement: Search scope toggle (All vs. Nearby)
`EarthquakeListView` SHALL implement `.searchScopes()` with two scopes: `.all` (search all earthquakes in the date range) and `.nearby` (search only earthquakes within 500km of the user's location). The scope SHALL default to `.all`.

#### Scenario: Nearby scope filters by distance
- **WHEN** the user selects the "Nearby" search scope and location is authorized
- **THEN** only earthquakes within 500km of the user's current location are shown

#### Scenario: Nearby scope unavailable without location
- **WHEN** the user selects "Nearby" and location permission is denied
- **THEN** a message is shown prompting the user to enable location access; all results are shown

#### Scenario: All scope shows no distance filter
- **WHEN** the user selects the "All" search scope
- **THEN** all magnitude-filtered earthquakes in the date range are shown regardless of location

### Requirement: Recent searches stored and shown as suggestions
The last 5 unique non-empty search queries SHALL be stored in `@AppStorage("recentSearches")` as JSON-encoded `[String]`. They SHALL appear as suggestions in the `.searchSuggestions()` modifier when the search bar is active and the query is empty.

#### Scenario: Recent searches appear as suggestions
- **WHEN** the user focuses the search bar and has previous searches
- **THEN** up to 5 recent searches are shown as tappable suggestions

#### Scenario: Tapping suggestion populates search bar
- **WHEN** the user taps a recent search suggestion
- **THEN** the search text is set to that suggestion and results update

#### Scenario: Most recent query added to suggestions
- **WHEN** the user performs a search and clears the search bar
- **THEN** the most recent query is added to the front of the suggestions list

#### Scenario: Duplicate suggestions deduplicated
- **WHEN** the user searches for a query that already exists in recent searches
- **THEN** the duplicate is removed from its old position and added to the front

### Requirement: Empty state view when no results found
`EarthquakeListView` SHALL show an empty-state view when `searchResults` is empty. The view SHALL explain why results are empty (no matching quakes vs. loading error) and offer a recovery action.

#### Scenario: Empty state for no search matches
- **WHEN** the search returns zero results
- **THEN** a message "No earthquakes matching '[query]'" is displayed with a "Clear Search" button

#### Scenario: Empty state for no quakes in date range
- **WHEN** the search text is empty and the API returns no earthquakes for the selected date range
- **THEN** a message "No earthquakes in this time range" is displayed with a "Change Dates" button that opens SettingsView
