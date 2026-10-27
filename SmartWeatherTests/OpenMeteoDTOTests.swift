import Foundation
import Testing

@Suite("Open-Meteo DTO & Mapper Tests")
struct OpenMeteoDTOTests {

    @Test("Decodes geocoding JSON payload into GeocodingResponse and locations")
    func geocodingResponseDecoding() throws {
        let json = """
        {
          "results": [
            {
              "id": 5856195,
              "name": "Honolulu",
              "latitude": 21.30694,
              "longitude": -157.85833,
              "country_code": "US",
              "country": "United States",
              "admin1": "Hawaii"
            },
            {
              "id": 5419384,
              "name": "Denver",
              "latitude": 39.73915,
              "longitude": -104.9847,
              "country_code": "US",
              "country": "United States",
              "admin1": "Colorado"
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(GeocodingResponse.self, from: json)
        let results = try #require(response.results)
        #expect(results.count == 2)

        let honolulu = results[0]
        #expect(honolulu.id == 5856195)
        #expect(honolulu.name == "Honolulu")
        #expect(honolulu.latitude == 21.30694)
        #expect(honolulu.longitude == -157.85833)
        #expect(honolulu.countryCode == "US")
        #expect(honolulu.country == "United States")
        #expect(honolulu.admin1 == "Hawaii")
        #expect(honolulu.displayName == "Honolulu, Hawaii, United States")

        let denver = results[1]
        #expect(denver.displayName == "Denver, Colorado, United States")
    }

    @Test("Decodes 7-day forecast JSON payload with daily metric arrays")
    func forecastResponseDecoding() throws {
        let json = """
        {
          "latitude": 39.74,
          "longitude": -104.99,
          "daily": {
            "time": ["2026-11-01", "2026-11-02"],
            "temperature_2m_max": [12.5, 4.0],
            "temperature_2m_min": [-2.0, -8.0],
            "precipitation_sum": [0.0, 15.0],
            "precipitation_probability_max": [10, 85],
            "snowfall_sum": [0.0, 18.0],
            "wind_speed_10m_max": [14.0, 22.0]
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ForecastResponse.self, from: json)
        #expect(response.daily.time.count == 2)
        #expect(response.daily.temperature2mMax == [12.5, 4.0])
        #expect(response.daily.temperature2mMin == [-2.0, -8.0])
        #expect(response.daily.precipitationSum == [0.0, 15.0])
        #expect(response.daily.precipitationProbabilityMax == [10.0, 85.0])
        #expect(response.daily.snowfallSum == [0.0, 18.0])
        #expect(response.daily.windSpeed10mMax == [14.0, 22.0])
    }

    @Test("Decodes marine JSON payload with coastal wave data and inland nulls")
    func marineResponseDecoding() throws {
        let coastalJson = """
        {
          "latitude": 21.3,
          "longitude": -157.8,
          "daily": {
            "time": ["2026-11-01", "2026-11-02"],
            "wave_height_max": [1.8, 2.2],
            "wave_period_max": [13.0, 14.5]
          }
        }
        """.data(using: .utf8)!

        let coastalResponse = try JSONDecoder().decode(MarineResponse.self, from: coastalJson)
        let coastalDaily = try #require(coastalResponse.daily)
        #expect(coastalDaily.waveHeightMax == [1.8, 2.2])
        #expect(coastalDaily.wavePeriodMax == [13.0, 14.5])

        let inlandJson = """
        {
          "latitude": 39.7,
          "longitude": -104.9,
          "daily": {
            "time": ["2026-11-01", "2026-11-02"],
            "wave_height_max": [null, null],
            "wave_period_max": [null, null]
          }
        }
        """.data(using: .utf8)!

        let inlandResponse = try JSONDecoder().decode(MarineResponse.self, from: inlandJson)
        let inlandDaily = try #require(inlandResponse.daily)
        #expect(inlandDaily.waveHeightMax == [nil, nil])
        #expect(inlandDaily.wavePeriodMax == [nil, nil])
    }

    @Test("Maps combined forecast and coastal marine responses into DailyWeatherMetrics")
    func mapperWithCoastalMarineData() throws {
        let forecast = ForecastResponse(
            daily: DailyForecastData(
                time: ["2026-11-01", "2026-11-02"],
                temperature2mMin: [20.0, 21.0],
                temperature2mMax: [26.0, 27.0],
                precipitationSum: [0.0, 2.5],
                precipitationProbabilityMax: [5.0, 40.0],
                snowfallSum: [0.0, 0.0],
                windSpeed10mMax: [12.0, 16.0]
            )
        )

        let marine = MarineResponse(
            daily: DailyMarineData(
                time: ["2026-11-01", "2026-11-02"],
                waveHeightMax: [1.8, 2.2],
                wavePeriodMax: [13.0, 14.0]
            )
        )

        let metricsList = WeatherMetricsMapper.map(forecast: forecast, marine: marine)
        #expect(metricsList.count == 2)

        let day1 = metricsList[0]
        #expect(day1.temperatureMin == 20.0)
        #expect(day1.temperatureMax == 26.0)
        #expect(day1.precipitationSum == 0.0)
        #expect(day1.precipitationProbabilityMax == 5)
        #expect(day1.snowfallSum == 0.0)
        #expect(day1.windSpeedMax == 12.0)
        #expect(day1.waveHeightMax == 1.8)
        #expect(day1.wavePeriodMax == 13.0)

        let day2 = metricsList[1]
        #expect(day2.waveHeightMax == 2.2)
        #expect(day2.wavePeriodMax == 14.0)
    }

    @Test("Maps forecast with nil marine response into DailyWeatherMetrics with nil wave fields")
    func mapperWithNilMarineData() {
        let forecast = ForecastResponse(
            daily: DailyForecastData(
                time: ["2026-11-01"],
                temperature2mMin: [-5.0],
                temperature2mMax: [2.0],
                precipitationSum: [12.0],
                precipitationProbabilityMax: [80.0],
                snowfallSum: [15.0],
                windSpeed10mMax: [18.0]
            )
        )

        let metricsList = WeatherMetricsMapper.map(forecast: forecast, marine: nil)
        #expect(metricsList.count == 1)

        let day = metricsList[0]
        #expect(day.temperatureMin == -5.0)
        #expect(day.temperatureMax == 2.0)
        #expect(day.snowfallSum == 15.0)
        #expect(day.waveHeightMax == nil)
        #expect(day.wavePeriodMax == nil)
    }

    @Test("Mapper safely handles mismatched array lengths without crashing")
    func mapperMismatchedArrayLengths() {
        let forecast = ForecastResponse(
            daily: DailyForecastData(
                time: ["2026-11-01", "2026-11-02", "2026-11-03"],
                temperature2mMin: [10.0, 11.0], // Length 2 (shorter)
                temperature2mMax: [20.0, 21.0, 22.0],
                precipitationSum: [0.0, 0.0, 0.0],
                precipitationProbabilityMax: [0.0, 0.0, 0.0],
                snowfallSum: [0.0, 0.0, 0.0],
                windSpeed10mMax: [10.0, 10.0, 10.0]
            )
        )

        let metricsList = WeatherMetricsMapper.map(forecast: forecast, marine: nil)
        // Should clamp to shortest mandatory array count (2)
        #expect(metricsList.count == 2)
    }
}
