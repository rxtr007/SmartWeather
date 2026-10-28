# Engineering Notes: SmartWeather Native iOS Application

## 1. Environment & Reconnaissance Record
- **macOS**: 27.0.1 (Build 26A434) on Apple Silicon
- **Xcode Toolchain**: Xcode 27.1 RC (`27A9275`) at `/Applications/Xcode-27.1.0-Release.Candidate.app/Contents/Developer`
- **Swift Compiler**: Apple Swift 6.4 (Swift 6 language mode, strict concurrency)
- **Deployment Target**: iOS 27.1
- **Simulator Device**: iPhone Duo (`688EF1D6-2896-4DD9-A266-3BD5CCD8B242`, iOS 27.1)
- **Fast Test Harness**: macOS sub-second Swift 6 compiler runner (`Tools/run-domain-tests.sh`)
- **Code Coverage**: 88.29% line coverage / 82.61% function coverage across all domain, data, network, and ViewModel logic via LLVM source-based instrumentation (`Tools/run-coverage.sh`)

## 2. Community Skills & Tooling Usage Record
| Skill / Tool | Source Repository | Purpose / Phase | Status & Findings |
| :--- | :--- | :--- | :--- |
| `duo-doctor` | `Kimeur/duology` | Phase A Environment validation | **Passed**: All 6 required checks verified (Xcode 27.1 RC, iOS 27.1 SDK, Duo device). |
| `duo-lint` | `Kimeur/duology` | Continuous static analysis (DUO001–DUO009) | **Active**: 0 warnings across all project Swift files. |
| `swift-testing-expert` | `AvdLee/swift-testing-agent-skill` | Test architecture & assertions | **Active**: Modern Apple Swift Testing framework (`@Suite`, `@Test`, `#expect`, `#require`). |
| `agent-skills` | `addyosmani/agent-skills` | TDD & incremental implementation | **Active**: Guiding red-green-refactor cycles and small-task scoping. |
| `swiftui-pro` | `twostraws/swiftui-agent-skill` | SwiftUI architecture & best practices | **Active**: Enforcing clean data flow, modern Swift 6 patterns, and view composition. |
| `swiftui-iphone-duo` | `FloWritesCode/fwc-swiftui-skills` | Adaptive layout & fold guidelines | **Active**: Tier 1 universal adaptive -> Tier 2 fold-safe layout plan. |

## 3. Representative TDD Cycles

### Cycle 1: Core Domain Value Types (`ActivityType`, `DailyWeatherMetrics`, `SuitabilityScore`)
- **Behavior under test**: Representing the 4 target activities, capturing raw meteorological measurements (with optional marine wave fields), score clamping to $0\dots100$, status categorization (`.suitable`, `.marginal`, `.unsuitable`), and handling missing/unavailable data explicitly.
- **Test defined**: `SmartWeatherTests/DomainModelTests.swift`
- **Expected failure observed**: Missing types `ActivityType`, `DailyWeatherMetrics`, `SuitabilityScore`, `SuitabilityStatus`.
- **Minimum implementation**: Created `ActivityType.swift`, `DailyWeatherMetrics.swift`, `SuitabilityScore.swift`.
- **Passing outcome**: 27 unit tests passed in 1 second.
- **Commit**: `7e22978 feat(domain): add ActivityType, DailyWeatherMetrics, and SuitabilityScore models`

### Cycle 2: Skiing Suitability Scoring Engine (`SkiingScorer`)
- **Behavior under test**: Deterministic calculation of skiing suitability score (0–100) based on fresh powder accumulation, temperature ranges (optimal $-8^\circ\text{C}\dots-2^\circ\text{C}$), severe slush penalty for above-freezing rain, and high wind lift closures ($>55\text{ km/h}$).
- **Test defined**: `SmartWeatherTests/SkiingScorerTests.swift`
- **Expected failure observed**: Missing `SkiingScorer` symbol in scope.
- **Minimum implementation**: Created `SkiingScorer.swift` evaluating snowfall base, temperature bonuses/penalties, liquid rain penalties, wind hold penalties, and descriptive explanation synthesis.
- **Passing outcome**: 38 tests passed. Ideal powder: 90 (Suitable); Cold groomed: 50 (Marginal); Warm slush: 0 (Unsuitable); High wind: 55 (Lift closures penalized).
- **Commit**: `56f9cbb feat(scoring): implement SkiingScorer with TDD`

### Cycle 3: Surfing Suitability Scoring Engine (`SurfingScorer`)
- **Behavior under test**: Deterministic evaluation of wave height ($1.2\text{m}\dots2.4\text{m}$ sweet spot), wave period groundswell bonus ($>12\text{s}$), surface chop and onshore wind penalties ($>28\text{ km/h}$), and explicit `.unavailable` status when marine wave data is absent (inland locations).
- **Test defined**: `SmartWeatherTests/SurfingScorerTests.swift`
- **Expected failure observed**: Missing `SurfingScorer` symbol in scope.
- **Minimum implementation**: Created `SurfingScorer.swift` validating marine metric presence, calculating height base, period groundswell bonus, surface texture wind penalties, and descriptive explanations.
- **Passing outcome**: 50 tests passed. Ideal groundswell: 100 (Suitable); Flat waves: 0 (Unsuitable); Blown out wind: 30 (Unsuitable); Inland city: nil score and `.unavailable`.
- **Commit**: `9cf527b feat(scoring): implement SurfingScorer with TDD`

### Cycle 4: Outdoor Sightseeing Scoring Engine (`OutdoorSightseeingScorer`)
- **Behavior under test**: Deterministic calculation of outdoor walking and sightseeing suitability. Evaluates comfortable walking temperatures ($18^\circ\text{C}\dots24^\circ\text{C}$ sweet spot), severe rain penalties ($>10\text{mm}$ or $>80\%$ probability), sweltering heatwave penalties ($>34^\circ\text{C}$), and high wind discomfort ($>28\text{ km/h}$).
- **Test defined**: `SmartWeatherTests/OutdoorSightseeingScorerTests.swift`
- **Expected failure observed**: Missing `OutdoorSightseeingScorer` symbol in scope.
- **Minimum implementation**: Created `OutdoorSightseeingScorer.swift` with rain deductions, walking temperature zones, dry condition bonuses (conditioned on non-extreme temperatures), and human-readable explanation generation.
- **Passing outcome**: 60 tests passed. Ideal sunny: 100 (Suitable); Cool autumn: 75 (Suitable); Rainstorm: 10 (Unsuitable); 37°C heatwave: 40 (Marginal).
- **Commit**: `2dbb81c feat(scoring): implement OutdoorSightseeingScorer with TDD`

### Cycle 5: Indoor Sightseeing Scoring Engine (`IndoorSightseeingScorer`)
- **Behavior under test**: Deterministic calculation of indoor cultural sightseeing suitability (museums, galleries, aquariums). Evaluates inclement weather boosts (rain, cold, heatwave relief), pleasant outdoor weather dampeners, and severe transit hazard penalties (torrential storms $>35\text{mm}$ or gale winds $>65\text{ km/h}$).
- **Test defined**: `SmartWeatherTests/IndoorSightseeingScorerTests.swift`
- **Expected failure observed**: Missing `IndoorSightseeingScorer` symbol in scope.
- **Minimum implementation**: Created `IndoorSightseeingScorer.swift` balancing indoor refuge appeal with travel feasibility safeguards.
- **Passing outcome**: 71 tests passed. Rainy cold: 100 (Suitable); Heatwave: 80 (Suitable); Sunny outdoor day: 45 (Marginal); Severe storm transit hazard: 15 (Unsuitable).
- **Commit**: `2491441 feat(scoring): implement IndoorSightseeingScorer with TDD`

### Cycle 6: Activity Ranking Engine (`ActivityRankingEngine` & `DailyAssessment`)
- **Behavior under test**: Aggregating raw meteorological metrics across all four activities in `DailyAssessment`, sorting forecast days deterministically by score descending (with unavailable days ranked last), and applying secondary tie-breakers (lower rain probability, lower rain volume, lower wind speed, and chronological order).
- **Test defined**: `SmartWeatherTests/ActivityRankingEngineTests.swift`
- **Expected failure observed**: Missing `DailyAssessment` and `ActivityRankingEngine` symbols in scope.
- **Minimum implementation**: Created `DailyAssessment.swift` and `ActivityRankingEngine.swift` returning `[RankedDay]` with 1-based ranks.
- **Passing outcome**: 88 tests passed. Multi-day ranking, tie-breaking by rain risk, and unavailable placement verified.
- **Commit**: `2d94d69 feat(domain): implement DailyAssessment and ActivityRankingEngine with TDD`

### Cycle 7: Swift Testing Framework Modernization
- **Behavior under test**: Migrating all unit, domain, and ranking tests to Apple's modern `import Testing` framework. Adopting `@Suite`, `@Test`, `#expect`, and `#require` for clean preconditions without manual guard boilerplate.
- **Test defined**: Modernized all test suites (`SanityTests`, `DomainModelTests`, `SkiingScorerTests`, `SurfingScorerTests`, `OutdoorSightseeingScorerTests`, `IndoorSightseeingScorerTests`, `ActivityRankingEngineTests`).
- **Runner integration**: Configured `Tools/run-domain-tests.sh` with Xcode 27.1 RC macOS `Testing.framework` search paths, runtime linker rpaths, and `libTestingMacros.dylib` compiler plugin.
- **Passing outcome**: 25 tests in 7 suites executed in 0.004s with zero assertions failed.
- **Commit**: `ab733a0 test: migrate domain unit tests to Apple Swift Testing framework`

### Cycle 8: Open-Meteo DTOs & Domain WeatherMetricsMapper
- **Behavior under test**: Decoding Open-Meteo wire JSON formats for Geocoding (`GeocodingResponse`, `GeocodingLocation`), Forecast (`ForecastResponse`, `DailyForecastData`), and Marine (`MarineResponse`, `DailyMarineData` with null wave handling). Mapping parallel meteorological arrays into domain `[DailyWeatherMetrics]` with resilient fallback for inland locations and array length discrepancies.
- **Test defined**: `SmartWeatherTests/OpenMeteoDTOTests.swift` (6 tests).
- **Expected failure observed**: Missing types `GeocodingResponse`, `ForecastResponse`, `MarineResponse`, `WeatherMetricsMapper` in scope.
- **Minimum implementation**: Created `GeocodingResponse.swift`, `ForecastResponse.swift`, `MarineResponse.swift` in `SmartWeather/Data/DTOs/` and `WeatherMetricsMapper.swift` in `SmartWeather/Data/Mappers/`. Added Data groups to Xcode project.
- **Passing outcome**: 31 tests in 8 suites passed in 0.008s. Full Xcode build succeeded with 0 warnings.
- **Commit**: `050aa0f feat(data): implement Open-Meteo DTOs and WeatherMetricsMapper with TDD`

### Cycle 9: Open-Meteo Network Client & Service Abstraction
- **Behavior under test**: Concrete URLSession network client for Open-Meteo Geocoding (`/v1/search`), Forecast (`/v1/forecast`), and Marine (`/v1/marine`) endpoints. Validating query trimming (empty queries return `[]` without network requests), error mapping (`OpenMeteoError.httpError`), parallel forecast + marine requests via `async let`, and inland marine 400 graceful degradation.
- **Test defined**: `SmartWeatherTests/OpenMeteoClientTests.swift` (5 tests using nonisolated `MockURLProtocol`).
- **Expected failure observed**: Missing types `OpenMeteoClient`, `OpenMeteoError`, and actor isolation mismatch on `MockURLProtocol`.
- **Minimum implementation**: Created `OpenMeteoError.swift`, `WeatherServiceProtocol.swift`, and `OpenMeteoClient.swift` under `SmartWeather/Data/Network/`. Configured dependency injection for `URLSession`.
- **Passing outcome**: 36 tests in 9 suites passed in 0.019s. App build succeeded with 0 warnings.
- **Commit**: `d4b4630 feat(network): implement OpenMeteoClient and WeatherServiceProtocol with TDD`

### Cycle 10: State Management & WeatherPlannerViewModel
- **Behavior under test**: MainActor `@Observable` ViewModel coordinating location search, asynchronous request debouncing, active task cancellation to avoid stale data races, forecast loading, dynamic 7-day activity re-ranking, and error state transitions.
- **Test defined**: `SmartWeatherTests/WeatherPlannerViewModelTests.swift` (6 tests using `MockWeatherService`).
- **Expected failure observed**: Missing type `WeatherPlannerViewModel` in scope.
- **Minimum implementation**: Created `SmartWeather/Presentation/ViewModels/WeatherPlannerViewModel.swift` with structured task management (`searchTask`, `forecastTask`), configurable debounce interval, and computed `rankedDays` property.
- **Passing outcome**: 42 tests in 10 suites passed in 0.078s. Xcode build succeeded with 0 warnings.
- **Commit**: `4c502c8 feat(presentation): implement WeatherPlannerViewModel with debouncing and TDD`

### Cycle 11: SwiftUI Presentation Layer & iPhone Duo Responsive Layouts
- **Behavior under test**: Native SwiftUI interface providing first-class user experience across conventional single-display iPhones and the foldable iPhone Duo. Includes compact single-pane layout (`CompactPlannerView`) and dual-pane split view (`ExpandedPlannerView`), with horizontal activity filter pill bar (`ActivityPickerBar`), ranked forecast day card with score badges (`RankedDayCard`), full meteorological detail inspector (`DayDetailView`), and debounced search field with suggestions (`LocationSearchBar`). Guarantees state continuity across fold/unfold postures by binding both views to the same `WeatherPlannerViewModel` instance.
- **Verification**: Zero DUO001–DUO009 lint warnings (`duo-lint`). Full Xcode 27.1 RC compilation for iOS Simulator succeeded with 0 warnings. 42 unit tests passed in 0.053s.
- **Commit**: `9a870d4 feat(ui): implement responsive SwiftUI views and iPhone Duo layouts`

### Cycle 12A: Concurrency Hardening & Forecast Task Cancellation
- **Behavior under test**: Deterministic cancellation of earlier in-flight forecast tasks when rapid location selections occur. Hardened `@discardableResult public func selectLocation(_ location: GeocodingLocation) -> Task<Void, Never>` to store the active task synchronously on `@MainActor`, cancelling any prior task and cleanly catching `CancellationError` without surfacing spurious error alerts.
- **Test defined**: `rapidLocationSelectionCancelsEarlierTask` in `SmartWeatherTests/WeatherPlannerViewModelTests.swift`.
- **Expected failure observed**: Initial compilation failure as `selectLocation` was previously `async` without returning the retained task handle.
- **Minimum implementation**: Updated `selectLocation` to launch and retain `self.forecastTask`, allowing SwiftUI callers to trigger location changes without launching uncoordinated detached tasks.
- **Passing outcome**: 43 tests in 10 suites passed in 0.058s. LLVM line coverage verified at 88.51%.
- **Commit**: `28fdffe feat(concurrency): harden forecast task ownership and cancellation in WeatherPlannerViewModel`

### Cycle 12B: Mobile Security Gate & Staged Pre-Commit Hook
- **Behavior under test**: Continuous static analysis protecting against secret leaks, insecure HTTP transport, dual-screen guideline violations, and OWASP mobile vulnerabilities.
- **Tooling integrated**: `mobsfscan` (MobSF Mobile Security Scanner), `duo-lint`, and ATS regex checks inside `Tools/run-security-scan.sh`.
- **Pre-commit configuration**: Created tracked `.githooks/pre-commit` configured via `git config core.hooksPath .githooks`. Automatically executes both `run-domain-tests.sh` and `run-security-scan.sh` before allowing commits.
- **Verification**: 0 secrets detected, 0 cleartext HTTP endpoints, 0 duo-lint findings, 0 high/critical MobSFScan findings.
- **Commit**: `13d4b03 feat(security): add MobSFScan static analysis and pre-commit security hook`

### Cycle 12C: UI/UX Refinement & Semantic Design Tokens
- **Behavior under test**: Elimination of duplicated badge styling across cards and detail screens by extracting `SuitabilityBadgeView` supporting `.compactPill` and `.prominentBanner` styles. Introduced semantic color token `Color.suitabilityColor(for:)` in `Color+AppTheme.swift` with enhanced contrast and accessible VoiceOver descriptions.
- **Verification**: App build succeeded with 0 warnings. 0 duo-lint violations across 37 files.
- **Commit**: `cd9b84f feat(ui): refine visual hierarchy and extract reusable SuitabilityBadgeView`

### Cycle 12D: iPhone Duo Simulator Verification & Demo Video Recording
- **Behavior under test**: End-to-end verification on the physical simulator hardware abstraction for iPhone Duo (`688EF1D6-2896-4DD9-A266-3BD5CCD8B242`).
- **Artifacts produced**:
  - `Screenshots/duo-outer-display.png`: Closed compact cover display (1398 × 2034).
  - `Screenshots/duo-inner-display.png`: Unfolded dual-pane display (2007 × 2853).
  - `Screenshots/demo-outer.mp4`: H.264 video capture of outer display interaction.
  - `Screenshots/demo-inner.mp4`: H.264 video capture of inner display interaction.
  - `Tools/record-demo.sh`: Repeatable video capture utility using `simctl io recordVideo`.
- **Commit**: `2960d9d feat(verification): capture iPhone Duo simulator dual-display screenshots and demo recordings`

### Cycle 12E: Search Field Synchronization on Location Selection
- **Behavior under test**: When a user enters a partial query (e.g. "Chopt") and selects a location from the autocomplete dropdown (e.g. "Chopta, Uttarakhand, India"), the search field text must immediately update to the selected city's full name (`location.name`), maintaining single source of truth across `@Observable WeatherPlannerViewModel` and `LocationSearchBar`.
- **Test defined**: `@Test("Selecting a location updates search query with selected city name")` in `SmartWeatherTests/WeatherPlannerViewModelTests.swift`.
- **Expected failure observed**: `Expectation failed: vm.searchQuery == "Innsbruck" (observed: "Inns")`.
- **Minimum implementation**: Assigned `searchQuery = location.name` inside `selectLocation(_:)` in `SmartWeather/Presentation/ViewModels/WeatherPlannerViewModel.swift` alongside existing clearing of search results and in-flight search task cancellation.
- **Passing outcome**: All 44 tests in 10 suites passed in 0.055s. Code coverage maintained at 88.52%. Security scan passed with 0 findings.


