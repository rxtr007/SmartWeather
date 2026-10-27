import Foundation
import Testing

/// Mock URLProtocol that intercepts network requests per test session.
nonisolated final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    nonisolated override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    nonisolated override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    nonisolated override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    nonisolated override func stopLoading() {}
}

@Suite("Open-Meteo Client Tests", .serialized)
struct OpenMeteoClientTests {

    private func makeTestClient(
        handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> OpenMeteoClient {
        MockURLProtocol.requestHandler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return OpenMeteoClient(session: session)
    }

    @Test("searchLocations returns locations for matching query")
    func searchLocationsSuccess() async throws {
        let json = """
        {
          "results": [
            {
              "id": 1850147,
              "name": "Tokyo",
              "latitude": 35.6895,
              "longitude": 139.6917,
              "country_code": "JP",
              "country": "Japan"
            }
          ]
        }
        """.data(using: .utf8)!

        let client = makeTestClient { request in
            #expect(request.url?.absoluteString.contains("name=Tokyo") == true)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, json)
        }

        let results = try await client.searchLocations(query: "Tokyo")
        #expect(results.count == 1)
        let first = try #require(results.first)
        #expect(first.name == "Tokyo")
        #expect(first.country == "Japan")
    }

    @Test("searchLocations returns empty array immediately for empty or whitespace query")
    func searchLocationsEmptyQuery() async throws {
        let client = makeTestClient { _ in
            Issue.record("Network request should not be made for empty query")
            throw URLError(.badURL)
        }

        let results = try await client.searchLocations(query: "   ")
        #expect(results.isEmpty)
    }

    @Test("searchLocations throws httpError on non-200 HTTP response")
    func searchLocationsHTTPError() async {
        let client = makeTestClient { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        await #expect(throws: OpenMeteoError.self) {
            _ = try await client.searchLocations(query: "Paris")
        }
    }

    @Test("fetchDailyMetrics combines forecast and coastal marine data successfully")
    func fetchDailyMetricsWithMarineData() async throws {
        let forecastJson = """
        {
          "latitude": 21.3,
          "longitude": -157.8,
          "daily": {
            "time": ["2026-11-01"],
            "temperature_2m_max": [28.0],
            "temperature_2m_min": [22.0],
            "precipitation_sum": [1.0],
            "precipitation_probability_max": [20],
            "snowfall_sum": [0.0],
            "wind_speed_10m_max": [15.0]
          }
        }
        """.data(using: .utf8)!

        let marineJson = """
        {
          "latitude": 21.3,
          "longitude": -157.8,
          "daily": {
            "time": ["2026-11-01"],
            "wave_height_max": [1.9],
            "wave_period_max": [13.5]
          }
        }
        """.data(using: .utf8)!

        let client = makeTestClient { request in
            let urlString = request.url?.absoluteString ?? ""
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            if urlString.contains("marine") {
                return (response, marineJson)
            } else {
                return (response, forecastJson)
            }
        }

        let metrics = try await client.fetchDailyMetrics(latitude: 21.3, longitude: -157.8)
        #expect(metrics.count == 1)
        let day = try #require(metrics.first)
        #expect(day.temperatureMax == 28.0)
        #expect(day.waveHeightMax == 1.9)
        #expect(day.wavePeriodMax == 13.5)
    }

    @Test("fetchDailyMetrics gracefully degrades to nil wave data when marine endpoint fails")
    func fetchDailyMetricsGracefulMarineDegradation() async throws {
        let forecastJson = """
        {
          "latitude": 39.7,
          "longitude": -104.9,
          "daily": {
            "time": ["2026-11-01"],
            "temperature_2m_max": [14.0],
            "temperature_2m_min": [-1.0],
            "precipitation_sum": [0.0],
            "precipitation_probability_max": [5],
            "snowfall_sum": [0.0],
            "wind_speed_10m_max": [12.0]
          }
        }
        """.data(using: .utf8)!

        let client = makeTestClient { request in
            let urlString = request.url?.absoluteString ?? ""
            if urlString.contains("marine") {
                // Simulate inland marine 400 error (no sea coordinates)
                let errorResponse = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
                return (errorResponse, Data())
            } else {
                let successResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (successResponse, forecastJson)
            }
        }

        let metrics = try await client.fetchDailyMetrics(latitude: 39.7, longitude: -104.9)
        #expect(metrics.count == 1)
        let day = try #require(metrics.first)
        #expect(day.temperatureMax == 14.0)
        #expect(day.waveHeightMax == nil)
        #expect(day.wavePeriodMax == nil)
    }
}
