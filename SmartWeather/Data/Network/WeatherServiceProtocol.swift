import Foundation

/// Protocol abstracting Open-Meteo weather and geocoding network services.
public protocol WeatherServiceProtocol: Sendable {
    /// Searches cities and locations matching the user's text query.
    func searchLocations(query: String) async throws -> [GeocodingLocation]

    /// Fetches 7-day daily weather forecast and optional marine wave metrics for a coordinate.
    func fetchDailyMetrics(latitude: Double, longitude: Double) async throws -> [DailyWeatherMetrics]
}
