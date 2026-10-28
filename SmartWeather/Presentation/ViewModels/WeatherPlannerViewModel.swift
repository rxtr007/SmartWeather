import Foundation
import Observation

/// Primary presentation view model driving location search, forecast retrieval, activity filtering, and rankings.
@Observable
@MainActor
public final class WeatherPlannerViewModel {
    // MARK: - Dependencies
    private let weatherService: WeatherServiceProtocol
    private let debounceNanoseconds: UInt64

    // MARK: - Active Async Tasks for Cancellation
    private var searchTask: Task<Void, Never>?
    private var forecastTask: Task<Void, Never>?

    // MARK: - Published State
    public var searchQuery: String = ""
    public var searchResults: [GeocodingLocation] = []
    public var isSearching: Bool = false

    public var selectedLocation: GeocodingLocation?
    public var isLoadingForecast: Bool = false
    public var errorMessage: String?

    public var dailyAssessments: [DailyAssessment] = []
    public var selectedActivity: ActivityType = .skiing
    public var selectedDay: RankedDay?

    // MARK: - Computed Properties
    public var rankedDays: [RankedDay] {
        guard !dailyAssessments.isEmpty else { return [] }
        return ActivityRankingEngine.rank(assessments: dailyAssessments, for: selectedActivity)
    }

    public var bestDayForSelectedActivity: RankedDay? {
        rankedDays.first
    }

    // MARK: - Initialization
    public init(
        weatherService: WeatherServiceProtocol = OpenMeteoClient(),
        debounceNanoseconds: UInt64 = 300_000_000 // 300ms default
    ) {
        self.weatherService = weatherService
        self.debounceNanoseconds = debounceNanoseconds
    }

    // MARK: - User Actions

    /// Handles changes in search query input, applying debouncing and cancelling obsolete requests.
    public func searchQueryDidChange(to newQuery: String) {
        searchQuery = newQuery
        searchTask?.cancel()

        let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        let debounce = debounceNanoseconds

        searchTask = Task { [weak self] in
            if debounce > 0 {
                do {
                    try await Task.sleep(nanoseconds: debounce)
                } catch {
                    return // Task cancelled early
                }
            }

            guard !Task.isCancelled else { return }

            do {
                guard let self else { return }
                let results = try await self.weatherService.searchLocations(query: trimmed)
                guard !Task.isCancelled else { return }
                self.searchResults = results
                self.isSearching = false
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                guard let self else { return }
                self.searchResults = []
                self.isSearching = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    /// Selects a location, cancels pending searches and prior forecast fetches, and retrieves 7-day weather metrics.
    @discardableResult
    public func selectLocation(_ location: GeocodingLocation) -> Task<Void, Never> {
        searchTask?.cancel()
        searchTask = nil
        forecastTask?.cancel()

        selectedLocation = location
        searchResults = []
        isSearching = false
        isLoadingForecast = true
        errorMessage = nil

        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let metrics = try await self.weatherService.fetchDailyMetrics(
                    latitude: location.latitude,
                    longitude: location.longitude
                )
                guard !Task.isCancelled else { return }
                self.dailyAssessments = metrics.map { DailyAssessment(metrics: $0) }
                self.selectedDay = self.rankedDays.first
                self.isLoadingForecast = false
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self.dailyAssessments = []
                self.selectedDay = nil
                self.isLoadingForecast = false
                self.errorMessage = error.localizedDescription
            }
        }

        self.forecastTask = task
        return task
    }

    /// Selects an activity filter, triggering recalculation of daily ranking orders.
    public func selectActivity(_ activity: ActivityType) {
        selectedActivity = activity
        if let currentDay = selectedDay {
            selectedDay = rankedDays.first(where: { $0.assessment.date == currentDay.assessment.date }) ?? rankedDays.first
        } else {
            selectedDay = rankedDays.first
        }
    }

    /// Selects a specific day to inspect detailed meteorological measurements and explanations.
    public func selectDay(_ day: RankedDay) {
        selectedDay = day
    }
}
