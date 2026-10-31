# SmartWeather — 7-Day Activity Suitability Planner for iPhone Duo


https://github.com/user-attachments/assets/cc3d5d43-ba0b-4397-a349-4287d3e88b07



https://github.com/user-attachments/assets/a5165cc9-2831-4507-b68e-1961cff8341f


**SmartWeather** is a native iOS application built with Swift 6 and SwiftUI, engineered specifically for conventional iPhones and foldable dual-screen devices (**iPhone Duo**). It retrieves meteorological and marine forecasts from Open-Meteo REST APIs to deterministically score and rank the best days of the week for four distinct outdoor and cultural activities:
1. **Skiing**: Evaluates fresh powder accumulation, freezing temperature zones, slush rain penalties, and gale-force wind hold risks.
2. **Surfing**: Analyzes coastal wave height sweet spots, long-period groundswell quality, onshore chop penalties, and gracefully flags inland destinations.
3. **Outdoor Sightseeing**: Balances comfortable walking temperatures, rain probability/volume deductions, and extreme heatwave hazards.
4. **Indoor Sightseeing**: Scores museums and galleries as ideal refuges during inclement rain or excessive heat, while safeguarding against severe storm transit hazards.

---

## Key Architectural Principles & PStack Discipline

The codebase adheres strictly to high-assurance mobile engineering practices:
- **Zero Third-Party Binary Bloat**: 100% native Apple SDKs (SwiftUI, Observation, Foundation, Swift Concurrency, Swift Testing). Zero pods or heavy SPM dependency graphs.
- **Clear Architectural Boundaries**:
  - `Domain/`: Pure value types (`DailyWeatherMetrics`, `SuitabilityScore`, `DailyAssessment`) and deterministic scoring algorithms (`SkiingScorer`, `SurfingScorer`, `OutdoorSightseeingScorer`, `IndoorSightseeingScorer`, `ActivityRankingEngine`). Zero UI or network dependencies.
  - `Data/`: Decoupled DTOs (`GeocodingResponse`, `ForecastResponse`, `MarineResponse`), robust domain mappers (`WeatherMetricsMapper`), and an isolated URLSession network client (`OpenMeteoClient`).
  - `Presentation/`: `@Observable @MainActor WeatherPlannerViewModel` coordinating async debounced searches, active task cancellation, and responsive ranking recalculations.
  - `Views/`: Adaptive SwiftUI hierarchy dynamically swapping between single-pane compact navigation (`CompactPlannerView`) and dual-pane fold-avoiding split views (`ExpandedPlannerView`) while preserving seamless state continuity across fold/unfold transitions.
- **Strict Swift Concurrency**: Default `@MainActor` UI isolation, `Sendable` domain models, structured task cancellation, and zero data-race hazards.

---

## iPhone Duo Foldable Adaptations

SmartWeather is verified compliant with Apple iPhone Duo guidelines (**DUO001–DUO009**):
- **Universal Adaptive Hierarchy**: Employs SwiftUI size classes (`horizontalSizeClass`) and standard controls rather than hardcoded device widths or legacy screen queries (`UIScreen.main`).
- **Outer Cover Display (`CompactPlannerView`)**: Single-column vertical scroll flow with debounced location search, activity pill selector, ranked day cards, and modal sheet day inspector.
- **Inner Unfolded Display (`ExpandedPlannerView`)**: Two-pane `NavigationSplitView` presenting the searchable ranked day list in the primary sidebar, with detailed meteorological analysis pinned in the detail pane—automatically respecting the central hinge/fold.
- **State Continuity**: Both outer and inner views share the exact same `@State var viewModel` in `PlannerRootView`, ensuring uninterrupted state continuity when the user opens or closes the device.

---

## Apple Swift Testing Suite (100% Modern Swift Testing)

All tests are authored using Apple's modern **Swift Testing** framework (`import Testing`, `@Suite`, `@Test`, `#expect`, `#require`), with zero legacy XCTest dependencies.

### Executing the Fast Test Harness
Unit and domain tests compile and execute in **under 0.1 seconds** on macOS:
```bash
./Tools/run-domain-tests.sh
```

### LLVM Source-Based Code Coverage
To instrument and generate an exact LLVM code coverage report:
```bash
./Tools/run-coverage.sh
```
**Coverage Verification**:
- **Line Coverage**: **88.51%** (747 / 844 lines across Domain, Data, and ViewModel layers)
- **Function Coverage**: **82.80%** (77 / 93 functions)
- **Suites**: 10 suites, **43 passing tests**

---

## Mobile Security & Pre-Commit Quality Gate

SmartWeather implements mobile security controls aligned with the **OWASP Mobile Application Security Verification Standard (MASVS / MASTG)**:
- **Zero Cleartext HTTP**: All endpoints strictly enforce TLS (`https://geocoding-api.open-meteo.com`, `https://api.open-meteo.com`, `https://marine-api.open-meteo.com`).
- **Zero Secrets / API Keys**: Keyless Open-Meteo REST endpoints; zero credentials stored in client code.
- **Zero Device Permissions**: Zero intrusive runtime permissions (no GPS/location daemon access required).
- **Automated Security Scan**: `Tools/run-security-scan.sh` executes:
  1. Secret & credential leak detection.
  2. Cleartext transport & App Transport Security (ATS) enforcement.
  3. iPhone Duo compliance linting (`duo-lint`).
  4. Static analysis via **MobSFScan** (`mobsfscan`), confirming 0 high/critical vulnerabilities.
- **Tracked Git Pre-Commit Hook**: Configured at `.githooks/pre-commit` (`git config core.hooksPath .githooks`), automatically running all Swift Testing suites and security scans on every staged commit.

---

## Building and Running on the iPhone Duo Simulator

### Build via Xcode Command Line
```bash
DEVELOPER_DIR=/Applications/Xcode-27.1.0-Release.Candidate.app/Contents/Developer \
xcodebuild -project SmartWeather.xcodeproj -scheme SmartWeather -destination 'id=688EF1D6-2896-4DD9-A266-3BD5CCD8B242' build
```

### Install and Launch on Simulator
```bash
xcrun simctl install 688EF1D6-2896-4DD9-A266-3BD5CCD8B242 /Users/provider.op/Library/Developer/Xcode/DerivedData/SmartWeather-bmfnisncspakikhkvxtalkqddako/Build/Products/Debug-iphonesimulator/SmartWeather.app
xcrun simctl launch 688EF1D6-2896-4DD9-A266-3BD5CCD8B242 com.example.SmartWeather
```

### Working Examples & Video Walkthroughs

The [`videos/`](https://github.com/rxtr007/SmartWeather/tree/f54c7a76f57ee76445698be94f95c39ecc0e690e/videos) directory contains working video demonstrations of SmartWeather running on both a physical device and the foldable iPhone Duo simulator:

| Demo Video                                                                                                                                                   | Environment                              | Key Behaviors Demonstrated                                                                                                                           |
| :------------------------------------------------------------------------------------------------------------------------------------------------------------ | :---------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**`SmartWeather_iPhoneDuo_small.mp4`**](https://github.com/rxtr007/SmartWeather/tree/f54c7a76f57ee76445698be94f95c39ecc0e690e/videos/SmartWeather_iPhoneDuo_small.mp4)           | iPhone Duo Simulator (iOS 27.1)          | Adaptive layout transitions between the single-column compact cover screen and expanded dual-pane `NavigationSplitView` across the foldable hinge.   |
| [**`SmartWeather_PhysicalDevice_small.mp4`**](https://github.com/rxtr007/SmartWeather/tree/f54c7a76f57ee76445698be94f95c39ecc0e690e/videos/SmartWeather_PhysicalDevice_small.mp4) | Physical iPhone 14 Pro Device (iOS 27.2) | Real-time interactive location search, async debouncing, live Open-Meteo API fetching, activity selector bar, and dynamic 7-day forecast re-ranking. |

---

### Dual-Display Local Recording Tooling
To record fresh demo videos on the booted simulator:
```bash
./Tools/record-demo.sh
```
