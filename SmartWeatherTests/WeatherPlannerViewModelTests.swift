import Foundation
import Testing

/// Mock WeatherService for deterministic ViewModel testing without network access.
final class MockWeatherService: WeatherServiceProtocol, @unchecked Sendable {
    var searchLocationsResult: Result<[GeocodingLocation], Error> = .success([])
    var fetchDailyMetricsResult: Result<[DailyWeatherMetrics], Error> = .success([])
    private(set) var searchCallCount = 0
    private(set) var fetchMetricsCallCount = 0
    var searchDelayNanoseconds: UInt64 = 0
    var fetchMetricsDelayNanoseconds: UInt64 = 0

    func searchLocations(query: String) async throws -> [GeocodingLocation] {
        searchCallCount += 1
        if searchDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: searchDelayNanoseconds)
        }
        return try searchLocationsResult.get()
    }

    func fetchDailyMetrics(latitude: Double, longitude: Double) async throws -> [DailyWeatherMetrics] {
        fetchMetricsCallCount += 1
        if fetchMetricsDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: fetchMetricsDelayNanoseconds)
        }
        return try fetchDailyMetricsResult.get()
    }
}

@Suite("WeatherPlannerViewModel Tests")
@MainActor
struct WeatherPlannerViewModelTests {

    private func makeSampleMetrics(count: Int = 3) -> [DailyWeatherMetrics] {
        let baseDate = Date(timeIntervalSince1970: 1730000000)
        return (0..<count).map { i in
            DailyWeatherMetrics(
                date: baseDate.addingTimeInterval(Double(i) * 86400),
                temperatureMin: -5.0 + Double(i),
                temperatureMax: -1.0 + Double(i),
                precipitationSum: 10.0,
                precipitationProbabilityMax: 70,
                snowfallSum: 15.0 - Double(i * 3),
                windSpeedMax: 15.0,
                waveHeightMax: 1.5,
                wavePeriodMax: 12.0
            )
        }
    }

    private let sampleLocation = GeocodingLocation(
        id: 100,
        name: "Innsbruck",
        latitude: 47.2692,
        longitude: 11.4041,
        countryCode: "AT",
        country: "Austria",
        admin1: "Tyrol"
    )

    @Test("Initial state has sensible defaults")
    func initialState() {
        let mock = MockWeatherService()
        let vm = WeatherPlannerViewModel(weatherService: mock, debounceNanoseconds: 0)

        #expect(vm.searchQuery.isEmpty)
        #expect(vm.searchResults.isEmpty)
        #expect(vm.isSearching == false)
        #expect(vm.selectedLocation == nil)
        #expect(vm.isLoadingForecast == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.dailyAssessments.isEmpty)
        #expect(vm.rankedDays.isEmpty)
        #expect(vm.selectedActivity == .skiing)
        #expect(vm.selectedDay == nil)
    }

    @Test("Search query populates searchResults after debouncing")
    func searchSuccess() async throws {
        let mock = MockWeatherService()
        mock.searchLocationsResult = .success([sampleLocation])
        let vm = WeatherPlannerViewModel(weatherService: mock, debounceNanoseconds: 10_000_000) // 10ms

        vm.searchQueryDidChange(to: "Innsbruck")
        #expect(vm.isSearching == true)

        // Wait for debounce and async search completion
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(vm.searchResults.count == 1)
        #expect(vm.searchResults.first?.name == "Innsbruck")
        #expect(vm.isSearching == false)
        #expect(mock.searchCallCount == 1)
    }

    @Test("Empty search query immediately clears results without service call")
    func searchEmptyQuery() async throws {
        let mock = MockWeatherService()
        let vm = WeatherPlannerViewModel(weatherService: mock, debounceNanoseconds: 0)

        vm.searchQueryDidChange(to: "   ")
        #expect(vm.searchResults.isEmpty)
        #expect(vm.isSearching == false)
        #expect(mock.searchCallCount == 0)
    }

    @Test("Selecting a location cancels search, fetches weather, and computes activity rankings")
    func selectLocationSuccess() async throws {
        let mock = MockWeatherService()
        let sampleMetrics = makeSampleMetrics(count: 3)
        mock.fetchDailyMetricsResult = .success(sampleMetrics)
        let vm = WeatherPlannerViewModel(weatherService: mock, debounceNanoseconds: 0)

        await vm.selectLocation(sampleLocation).value

        #expect(vm.selectedLocation?.name == "Innsbruck")
        #expect(vm.isLoadingForecast == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.dailyAssessments.count == 3)
        #expect(vm.rankedDays.count == 3)

        // Verify ranked days are sorted with rank indices
        #expect(vm.rankedDays[0].rank == 1)
        #expect(vm.rankedDays[1].rank == 2)
        #expect(vm.rankedDays[2].rank == 3)

        // Default selected day is rank 1
        #expect(vm.selectedDay?.rank == 1)
    }

    @Test("Selecting a location updates search query with selected city name")
    func selectLocationUpdatesSearchQuery() async {
        let mock = MockWeatherService()
        let vm = WeatherPlannerViewModel(weatherService: mock, debounceNanoseconds: 0)
        vm.searchQuery = "Inns"

        await vm.selectLocation(sampleLocation).value

        #expect(vm.searchQuery == "Innsbruck")
        #expect(vm.selectedLocation?.name == "Innsbruck")
    }

    @Test("Selecting location handles forecast failure with error message")
    func selectLocationError() async {
        let mock = MockWeatherService()
        mock.fetchDailyMetricsResult = .failure(OpenMeteoError.httpError(statusCode: 503))
        let vm = WeatherPlannerViewModel(weatherService: mock, debounceNanoseconds: 0)

        await vm.selectLocation(sampleLocation).value

        #expect(vm.isLoadingForecast == false)
        #expect(vm.errorMessage != nil)
        #expect(vm.dailyAssessments.isEmpty)
        #expect(vm.rankedDays.isEmpty)
    }

    @Test("Switching selected activity dynamically re-ranks 7-day forecast")
    func switchActivityReranks() async {
        let mock = MockWeatherService()
        let sampleMetrics = makeSampleMetrics(count: 3)
        mock.fetchDailyMetricsResult = .success(sampleMetrics)
        let vm = WeatherPlannerViewModel(weatherService: mock, debounceNanoseconds: 0)

        await vm.selectLocation(sampleLocation).value

        #expect(vm.selectedActivity == .skiing)
        let skiBestDay = vm.bestDayForSelectedActivity

        vm.selectActivity(.outdoorSightseeing)
        #expect(vm.selectedActivity == .outdoorSightseeing)
        let outdoorBestDay = vm.bestDayForSelectedActivity

        #expect(skiBestDay != nil)
        #expect(outdoorBestDay != nil)
    }

    @Test("Rapid location selection cancels earlier in-flight forecast tasks")
    func rapidLocationSelectionCancelsEarlierTask() async {
        let mock = MockWeatherService()
        let innsbruckMetrics = makeSampleMetrics(count: 3)
        let honoluluMetrics = [
            DailyWeatherMetrics(
                date: Date(),
                temperatureMin: 22.0,
                temperatureMax: 28.0,
                precipitationSum: 0.0,
                precipitationProbabilityMax: 10,
                snowfallSum: 0.0,
                windSpeedMax: 12.0,
                waveHeightMax: 1.8,
                wavePeriodMax: 13.0
            )
        ]

        let honoluluLocation = GeocodingLocation(
            id: 200,
            name: "Honolulu",
            latitude: 21.3069,
            longitude: -157.8583,
            countryCode: "US",
            country: "United States",
            admin1: "Hawaii"
        )

        let vm = WeatherPlannerViewModel(weatherService: mock, debounceNanoseconds: 0)

        // Set Innsbruck with simulated network latency
        mock.fetchDailyMetricsResult = .success(innsbruckMetrics)
        mock.fetchMetricsDelayNanoseconds = 100_000_000 // 100ms
        let innsbruckTask = vm.selectLocation(sampleLocation)

        // Immediately switch to Honolulu with 0 latency
        mock.fetchDailyMetricsResult = .success(honoluluMetrics)
        mock.fetchMetricsDelayNanoseconds = 0
        let honoluluTask = vm.selectLocation(honoluluLocation)

        // Await Honolulu completion
        await honoluluTask.value
        _ = await innsbruckTask.result

        // Honolulu must win; Innsbruck's slower response must have been cancelled
        #expect(vm.selectedLocation?.name == "Honolulu")
        #expect(vm.dailyAssessments.count == 1)
        #expect(vm.dailyAssessments.first?.metrics.temperatureMax == 28.0)
    }
}
