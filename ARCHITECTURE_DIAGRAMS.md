# SmartWeather — Architecture & System Overview Diagrams

This document contains visual architectural diagrams for **SmartWeather** rendered using standard GitHub-compatible [Mermaid](https://mermaid.js.org/) syntax. You can view these directly on GitHub, in VS Code/Xcode markdown previewers, or in any Mermaid-compatible viewer.

---

## 1. High-Level System Architecture & Clean Architecture Data Flow

```mermaid
flowchart TD
    subgraph UI["Presentation Layer (SwiftUI + Observation)"]
        Root["PlannerRootView<br/>(@Environment horizontalSizeClass)"]
        Compact["CompactPlannerView<br/>(Single-Pane / Outer Cover)"]
        Expanded["ExpandedPlannerView<br/>(NavigationSplitView / Inner Display)"]
        VM["WeatherPlannerViewModel<br/>(@Observable @MainActor)"]
        
        Root --> Compact
        Root --> Expanded
        Compact --> VM
        Expanded --> VM
    end

    subgraph Domain["Domain Layer (Pure Swift / Zero UI / Thread-Safe)"]
        Engine["ActivityRankingEngine<br/>(7-Day Descending Sorter)"]
        Assessment["DailyAssessment<br/>(Multi-Activity Evaluator)"]
        Scorers["Activity Scorers<br/>• SkiingScorer<br/>• SurfingScorer<br/>• OutdoorSightseeingScorer<br/>• IndoorSightseeingScorer"]
        Models["Domain Models<br/>• DailyWeatherMetrics<br/>• SuitabilityScore<br/>• ActivityType"]

        VM --> Engine
        Engine --> Assessment
        Assessment --> Scorers
        Scorers --> Models
    end

    subgraph Data["Data Layer (Networking & Serialization)"]
        Proto["WeatherServiceProtocol"]
        Client["OpenMeteoClient<br/>(URLSession + async/await)"]
        Mapper["WeatherMetricsMapper<br/>(Bounds-checked Mapper)"]
        DTOs["API DTOs<br/>• GeocodingResponse<br/>• ForecastResponse<br/>• MarineResponse"]

        VM --> Proto
        Client -.->|conforms to| Proto
        Client --> DTOs
        DTOs --> Mapper
        Mapper --> Models
    end

    subgraph External["External APIs (HTTPS Only)"]
        GeoAPI["Open-Meteo Geocoding API<br/>(/v1/search)"]
        ForecastAPI["Open-Meteo Forecast API<br/>(/v1/forecast)"]
        MarineAPI["Open-Meteo Marine API<br/>(/v1/marine)"]

        Client --> GeoAPI
        Client --> ForecastAPI
        Client --> MarineAPI
    end
```

---

## 2. iPhone Duo Adaptive Layout & State Continuity

```mermaid
flowchart TD
    Device{"Device Form Factor<br/>& Posture Detection"}
    
    Device -->|"horizontalSizeClass == .compact<br/>(Closed Phone / Outer Display)"| CompactLayout["CompactPlannerView"]
    Device -->|"horizontalSizeClass == .regular<br/>(Unfolded Dual Screen)"| SplitLayout["ExpandedPlannerView"]
    
    subgraph SingleState["Shared State Machine (@MainActor)"]
        SharedVM["WeatherPlannerViewModel<br/>• searchQuery<br/>• selectedLocation<br/>• selectedActivity<br/>• selectedDay"]
    end
    
    subgraph OuterFlow["Outer Display Experience (1398 x 2034)"]
        CompactLayout --> SearchBar1["LocationSearchBar"]
        CompactLayout --> ActivityBar1["ActivityPickerBar"]
        CompactLayout --> List1["7-Day Ranked Card List"]
        List1 -->|"Tap Card"| Sheet["Modal Sheet: DayDetailView"]
    end
    
    subgraph InnerFlow["Inner Unfolded Dual-Display (2007 x 2853)"]
        SplitLayout --> SidebarPane["Left Screen (Sidebar Pane)<br/>• LocationSearchBar<br/>• ActivityPickerBar<br/>• 7-Day Ranked Card List"]
        SplitLayout --> Hinge["[ Central Physical Hinge ]"]
        Hinge --> DetailPane["Right Screen (Detail Pane)<br/>• Suitability Banner<br/>• Detailed Meteorological Grid"]
    end

    SharedVM -.-> CompactLayout
    SharedVM -.-> SplitLayout
```

---

## 3. Asynchronous Data Flow & Race Condition Safeguards

```mermaid
sequenceDiagram
    autonumber
    actor User as User
    participant View as LocationSearchBar
    participant VM as WeatherPlannerViewModel (@MainActor)
    participant Client as OpenMeteoClient
    participant API as Open-Meteo REST APIs

    User->>View: Types "Chopt"
    View->>VM: searchQueryDidChange("Chopt")
    Note over VM: Cancels previous searchTask<br/>Starts 300ms debounce timer
    
    VM->>Client: searchLocations("Chopt")
    Client->>API: GET /v1/search?name=Chopt
    API-->>Client: Returns GeocodingResponse JSON
    Client-->>VM: [GeocodingLocation("Chopta, Uttarakhand, India")]
    VM-->>View: Updates searchResults dropdown

    User->>View: Taps "Chopta, India"
    View->>VM: selectLocation(location)
    Note over VM: 1. Synchronously cancels searchTask<br/>2. Synchronously cancels prior forecastTask<br/>3. Sets searchQuery = "Chopta"<br/>4. Sets isLoadingForecast = true

    par Concurrent Network Requests via async let
        VM->>Client: fetchDailyMetrics(lat, lon)
        Client->>API: GET /v1/forecast (Weather Metrics)
        Client->>API: GET /v1/marine (Wave Data)
    end

    alt Inland Coordinates (Marine API returns 400 or empty)
        API-->>Client: Marine request fails / 400
        Note over Client: Gracefully catches error<br/>Sets marineData = nil (No failure cascade)
    else Coastal Coordinates
        API-->>Client: Marine wave height & period data
    end

    API-->>Client: Forecast response (7-day temperatures, rain, snow, wind)
    Client-->>VM: [DailyWeatherMetrics] (7 days)
    
    Note over VM: Runs ActivityRankingEngine<br/>Evaluates all 4 activity scorers<br/>Sorts 7 days in descending order
    VM-->>View: Updates rankedDays & selectedDay (UI renders instantly)
```

---

## 4. ViewModel State Machine

```mermaid
stateDiagram-v2
    [*] --> Idle: App Launch (Default: Tokyo, Skiing)

    state Searching {
        Debouncing --> FetchingLocations: 300ms Timer Fires
        FetchingLocations --> ResultsReady: Success
        FetchingLocations --> SearchError: Network Failure
    }

    state ForecastLoading {
        CancellingPriorTasks --> FetchingWeather: Synchronous Cancel
        FetchingWeather --> ComputingRankings: Open-Meteo Success
        FetchingWeather --> ForecastError: Network Failure
    }

    Idle --> Searching: User Types Query
    Searching --> Searching: User Continues Typing (Debounce reset)
    Searching --> ForecastLoading: User Selects Autocomplete Suggestion
    ForecastLoading --> Idle: 7-Day Rankings Computed
    Idle --> Idle: User Taps Different Activity (Instant In-Memory Re-rank)
    Idle --> Idle: User Taps Different Day (Updates Detail Inspector)
```
