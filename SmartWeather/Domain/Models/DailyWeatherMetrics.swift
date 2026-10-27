import Foundation

/// Encapsulates direct weather measurements and forecast metrics for a single calendar day.
/// All physical units follow Open-Meteo defaults: Celsius for temperatures, mm for precipitation,
/// cm for snowfall, km/h for wind speed, meters for wave height, and seconds for wave period.
public struct DailyWeatherMetrics: Sendable, Equatable, Hashable, Codable {
    public let date: Date
    public let temperatureMin: Double
    public let temperatureMax: Double
    public let precipitationSum: Double
    public let precipitationProbabilityMax: Int
    public let snowfallSum: Double
    public let windSpeedMax: Double
    
    // Marine variables (optional, nil for inland locations)
    public let waveHeightMax: Double?
    public let wavePeriodMax: Double?
    
    public init(
        date: Date,
        temperatureMin: Double,
        temperatureMax: Double,
        precipitationSum: Double,
        precipitationProbabilityMax: Int,
        snowfallSum: Double,
        windSpeedMax: Double,
        waveHeightMax: Double? = nil,
        wavePeriodMax: Double? = nil
    ) {
        self.date = date
        self.temperatureMin = temperatureMin
        self.temperatureMax = temperatureMax
        self.precipitationSum = precipitationSum
        self.precipitationProbabilityMax = precipitationProbabilityMax
        self.snowfallSum = snowfallSum
        self.windSpeedMax = windSpeedMax
        self.waveHeightMax = waveHeightMax
        self.wavePeriodMax = wavePeriodMax
    }
}
