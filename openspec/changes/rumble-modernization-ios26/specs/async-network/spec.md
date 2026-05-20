## ADDED Requirements

### Requirement: EarthquakeServiceProtocol uses async/await
`EarthquakeServiceProtocol` SHALL declare `func getEarthquakes(startTime: Date, endTime: Date) async throws -> GeoJSON`. No Combine types (`AnyPublisher`, `AnyCancellable`) SHALL appear in the protocol or its implementation.

#### Scenario: Protocol signature
- **WHEN** `EarthquakeServiceProtocol` is compiled
- **THEN** it declares exactly one method: `getEarthquakes(startTime:endTime:)` returning `GeoJSON` asynchronously

#### Scenario: No Combine import in NetworkManager
- **WHEN** `NetworkManager.swift` is compiled
- **THEN** no `import Combine` statement exists

### Requirement: Network errors are propagated and displayed
`EarthquakesState.fetchEarthquakes()` SHALL catch all errors thrown by the service and store them in an `error: Error?` property. Views displaying earthquake data SHALL present an `.alert` when `error` is non-nil.

#### Scenario: Error stored on network failure
- **WHEN** `getEarthquakes` throws a network error
- **THEN** `EarthquakesState.error` is set to the thrown error and `isLoading` is set to `false`

#### Scenario: Alert shown to user
- **WHEN** `EarthquakesState.error` is non-nil
- **THEN** `EarthquakeListView` presents an alert with the error's localized description and a "Retry" button

#### Scenario: Error cleared on retry
- **WHEN** the user taps "Retry" in the error alert
- **THEN** `EarthquakesState.error` is set to `nil` and `fetchEarthquakes()` is called again

### Requirement: Automatic retry with exponential backoff
The network client SHALL retry failed requests up to 2 times for transient `URLError` failures. The retry delays SHALL be 0.5 seconds and 1.0 seconds respectively.

#### Scenario: Retry on URLError
- **WHEN** a request fails with `URLError.notConnectedToInternet` or `URLError.timedOut`
- **THEN** the client retries up to 2 times before propagating the error

#### Scenario: No retry on non-transient errors
- **WHEN** a request fails with HTTP 404 or decoding error
- **THEN** the error is propagated immediately without retrying

### Requirement: Response caching via URLCache
The `URLSession` used for earthquake requests SHALL be configured with a `URLCache` of 10MB memory capacity and 50MB disk capacity. Requests SHALL use `cachePolicy: .returnCacheDataElseLoad`.

#### Scenario: Cached response used on repeat launch
- **WHEN** the app is launched and a cached response exists for the current date range
- **THEN** the cached earthquake data is displayed immediately while a fresh fetch runs in the background

### Requirement: Authorization header removed from USGS requests
`EarthquakeEndpoint` SHALL NOT include an `Authorization` header. The USGS fdsnws API is public and unauthenticated.

#### Scenario: No Authorization header
- **WHEN** a request is built by `EarthquakeEndpoint`
- **THEN** the request's `allHTTPHeaderFields` does not contain an `Authorization` key

### Requirement: Pull-to-refresh supported on earthquake list
`EarthquakeListView` SHALL support pull-to-refresh via the `.refreshable` modifier, triggering `fetchEarthquakes()`.

#### Scenario: Pull-to-refresh triggers fetch
- **WHEN** the user pulls down on the earthquake list
- **THEN** `EarthquakesState.fetchEarthquakes()` is called and the refresh spinner is shown until complete
