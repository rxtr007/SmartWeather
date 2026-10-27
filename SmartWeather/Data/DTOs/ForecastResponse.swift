import Foundation

/// Wire response from Open-Meteo Forecast API (`https://api.open-meteo.com/v1/forecast`)
public struct ForecastResponse: Codable, Sendable {
    public let daily: DailyForecastData

    public init(daily: DailyForecastData) {
        self.daily = daily
    }
}

/// Parallel metric arrays for daily weather forecast variables.
public struct DailyForecastData: Codable, Sendable {
    public let time: [String]
    public let temperature2mMin: [Double]
    public let temperature2mMax: [Double]
    public let precipitationSum: [Double]
    public let precipitationProbabilityMax: [Double?]
    public let snowfallSum: [Double]
    public let windSpeed10mMax: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2mMin = "temperature_2m_min"
        case temperature2mMax = "temperature_2m_max"
        case precipitationSum = "precipitation_sum"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case snowfallSum = "snowfall_sum"
        case windSpeed10mMax = "wind_speed_10m_max"
    }

    public init(
        time: [String],
        temperature2mMin: [Double],
        temperature2mMax: [Double],
        precipitationSum: [Double],
        precipitationProbabilityMax: [Double?],
        snowfallSum: [Double],
        windSpeed10mMax: [Double]
    ) {
        self.time = time
        self.temperature2mMin = temperature2mMin
        self.temperature2mMax = temperature2mMax
        self.precipitationSum = precipitationSum
        self.precipitationProbabilityMax = precipitationProbabilityMax
        self.snowfallSum = snowfallSum
        self.windSpeed10mMax = windSpeed10mMax
    }
}
