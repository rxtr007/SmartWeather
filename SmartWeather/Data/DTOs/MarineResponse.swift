import Foundation

/// Wire response from Open-Meteo Marine Weather API (`https://marine-api.open-meteo.com/v1/marine`)
public struct MarineResponse: Codable, Sendable {
    public let daily: DailyMarineData?

    public init(daily: DailyMarineData? = nil) {
        self.daily = daily
    }
}

/// Parallel metric arrays for marine wave variables.
public struct DailyMarineData: Codable, Sendable {
    public let time: [String]?
    public let waveHeightMax: [Double?]?
    public let wavePeriodMax: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case waveHeightMax = "wave_height_max"
        case wavePeriodMax = "wave_period_max"
    }

    public init(
        time: [String]? = nil,
        waveHeightMax: [Double?]? = nil,
        wavePeriodMax: [Double?]? = nil
    ) {
        self.time = time
        self.waveHeightMax = waveHeightMax
        self.wavePeriodMax = wavePeriodMax
    }
}
