import Foundation

/// Maps Open-Meteo wire DTOs (`ForecastResponse` and `MarineResponse`) into strongly-typed domain `DailyWeatherMetrics`.
public enum WeatherMetricsMapper {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// Maps forecast and optional marine responses into an array of `DailyWeatherMetrics`.
    ///
    /// - Parameters:
    ///   - forecast: The mandatory forecast response containing daily meteorological arrays.
    ///   - marine: An optional marine response containing daily wave height and period arrays.
    /// - Returns: An array of `DailyWeatherMetrics` aligned by day index.
    public static func map(
        forecast: ForecastResponse,
        marine: MarineResponse?
    ) -> [DailyWeatherMetrics] {
        let daily = forecast.daily
        
        // Find safe common bound across all required parallel forecast arrays
        let count = min(
            daily.time.count,
            daily.temperature2mMin.count,
            daily.temperature2mMax.count,
            daily.precipitationSum.count,
            daily.precipitationProbabilityMax.count,
            daily.snowfallSum.count,
            daily.windSpeed10mMax.count
        )

        guard count > 0 else { return [] }

        var results: [DailyWeatherMetrics] = []
        results.reserveCapacity(count)

        for i in 0..<count {
            let dateString = daily.time[i]
            let date = dateFormatter.date(from: dateString) ?? Date().addingTimeInterval(Double(i) * 86400)
            let tempMin = daily.temperature2mMin[i]
            let tempMax = daily.temperature2mMax[i]
            let precipSum = daily.precipitationSum[i]
            let precipProbDouble = daily.precipitationProbabilityMax[i] ?? 0.0
            let precipProb = Int(precipProbDouble)
            let snowfall = daily.snowfallSum[i]
            let windSpeed = daily.windSpeed10mMax[i]

            // Safely extract marine metrics if available for this day index
            var waveHeight: Double? = nil
            var wavePeriod: Double? = nil

            if let marineDaily = marine?.daily {
                if let waveHeights = marineDaily.waveHeightMax, i < waveHeights.count {
                    waveHeight = waveHeights[i]
                }
                if let wavePeriods = marineDaily.wavePeriodMax, i < wavePeriods.count {
                    wavePeriod = wavePeriods[i]
                }
            }

            let metrics = DailyWeatherMetrics(
                date: date,
                temperatureMin: tempMin,
                temperatureMax: tempMax,
                precipitationSum: precipSum,
                precipitationProbabilityMax: precipProb,
                snowfallSum: snowfall,
                windSpeedMax: windSpeed,
                waveHeightMax: waveHeight,
                wavePeriodMax: wavePeriod
            )

            results.append(metrics)
        }

        return results
    }
}
