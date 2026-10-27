import Foundation

/// Concrete network client communicating with Open-Meteo Geocoding, Forecast, and Marine Weather APIs.
public final class OpenMeteoClient: WeatherServiceProtocol, Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Searches cities and locations matching the user's text query.
    ///
    /// - Parameter query: The text search input entered by the user.
    /// - Returns: An array of `GeocodingLocation` results, or empty if query is blank.
    public func searchLocations(query: String) async throws -> [GeocodingLocation] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        guard var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search") else {
            throw OpenMeteoError.invalidURL("https://geocoding-api.open-meteo.com/v1/search")
        }

        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: "5"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else {
            throw OpenMeteoError.invalidURL(trimmed)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw OpenMeteoError.networkError(error.localizedDescription)
        }

        try validateHTTPResponse(response)

        do {
            let decoded = try JSONDecoder().decode(GeocodingResponse.self, from: data)
            return decoded.results ?? []
        } catch {
            throw OpenMeteoError.decodingError(error.localizedDescription)
        }
    }

    /// Fetches 7-day weather forecast and optional marine wave metrics for a coordinate,
    /// translating them into domain `DailyWeatherMetrics`.
    ///
    /// - Parameters:
    ///   - latitude: Geographic latitude.
    ///   - longitude: Geographic longitude.
    /// - Returns: An array of `DailyWeatherMetrics` for the upcoming 7 days.
    public func fetchDailyMetrics(latitude: Double, longitude: Double) async throws -> [DailyWeatherMetrics] {
        async let forecastTask = fetchForecast(latitude: latitude, longitude: longitude)
        async let marineTask = fetchMarineSafely(latitude: latitude, longitude: longitude)

        let (forecast, marine) = try await (forecastTask, marineTask)
        return WeatherMetricsMapper.map(forecast: forecast, marine: marine)
    }

    private func fetchForecast(latitude: Double, longitude: Double) async throws -> ForecastResponse {
        guard var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast") else {
            throw OpenMeteoError.invalidURL("https://api.open-meteo.com/v1/forecast")
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,snowfall_sum,wind_speed_10m_max"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components.url else {
            throw OpenMeteoError.invalidURL("Forecast coordinates: lat=\(latitude), lon=\(longitude)")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw OpenMeteoError.networkError(error.localizedDescription)
        }

        try validateHTTPResponse(response)

        do {
            return try JSONDecoder().decode(ForecastResponse.self, from: data)
        } catch {
            throw OpenMeteoError.decodingError(error.localizedDescription)
        }
    }

    private func fetchMarineSafely(latitude: Double, longitude: Double) async -> MarineResponse? {
        guard var components = URLComponents(string: "https://marine-api.open-meteo.com/v1/marine") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "daily", value: "wave_height_max,wave_period_max"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                // Inland coordinates return HTTP 400 with message "no sea coordinate".
                // Gracefully return nil so forecast is unaffected.
                return nil
            }
            return try JSONDecoder().decode(MarineResponse.self, from: data)
        } catch {
            // Network failure on marine endpoint degrades gracefully
            return nil
        }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw OpenMeteoError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}
