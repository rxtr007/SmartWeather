import Foundation

/// Deterministic scoring engine for surfing suitability.
/// Evaluates wave height, wave period, coastal surface winds, and handles missing marine data.
public struct SurfingScorer: Sendable {
    
    /// Evaluates daily weather metrics and returns a suitability score or unavailable state.
    public static func score(metrics: DailyWeatherMetrics) -> SuitabilityScore {
        // Marine wave data is required for a credible surf assessment.
        guard let waveHeight = metrics.waveHeightMax,
              let wavePeriod = metrics.wavePeriodMax else {
            return SuitabilityScore.unavailable(reason: "Marine wave data is unavailable for inland locations")
        }
        
        var rawScore = 0
        var explanationParts: [String] = []
        
        // 1. Wave height base evaluation (sweet spot: 1.2m - 2.4m)
        if waveHeight >= 1.2 && waveHeight <= 2.4 {
            rawScore += 65
            explanationParts.append("Ideal wave height (\(String(format: "%.1f", waveHeight)) m)")
        } else if waveHeight >= 0.8 && waveHeight < 1.2 {
            rawScore += 45
            explanationParts.append("Small, rideable wave height (\(String(format: "%.1f", waveHeight)) m)")
        } else if waveHeight > 2.4 && waveHeight <= 3.5 {
            rawScore += 50
            explanationParts.append("Challenging, heavy wave height (\(String(format: "%.1f", waveHeight)) m)")
        } else if waveHeight < 0.5 {
            rawScore += 10
            explanationParts.append("Flat, unrideable waves (\(String(format: "%.1f", waveHeight)) m)")
        } else if waveHeight > 4.0 {
            rawScore += 15
            explanationParts.append("Hazardous, oversized surf (\(String(format: "%.1f", waveHeight)) m)")
        } else {
            rawScore += 35
            explanationParts.append("Marginal wave height (\(String(format: "%.1f", waveHeight)) m)")
        }
        
        // 2. Wave period modifier (longer period means cleaner, more organized groundswell)
        if wavePeriod >= 12.0 {
            rawScore += 25
            explanationParts.append("powerful, clean groundswell (\(String(format: "%.0f", wavePeriod))s period)")
        } else if wavePeriod >= 9.0 {
            rawScore += 15
            explanationParts.append("medium-period swell (\(String(format: "%.0f", wavePeriod))s period)")
        } else if wavePeriod < 6.0 {
            rawScore -= 20
            explanationParts.append("short-period wind chop (\(String(format: "%.0f", wavePeriod))s period)")
        }
        
        // 3. Wind surface texture modifier
        if metrics.windSpeedMax < 15.0 {
            rawScore += 10
            explanationParts.append("clean, glassy surface with light winds")
        } else if metrics.windSpeedMax > 40.0 {
            rawScore -= 35
            explanationParts.append("strong winds (\(String(format: "%.0f", metrics.windSpeedMax)) km/h) causing blown-out chop")
        } else if metrics.windSpeedMax > 28.0 {
            rawScore -= 20
            explanationParts.append("bumpy surface from gusty onshore winds")
        }
        
        // 4. Air temperature comfort modifier
        if metrics.temperatureMax < 10.0 {
            rawScore -= 10
            explanationParts.append("cold air temperatures")
        }
        
        let explanation = explanationParts.joined(separator: ", ").capitalizedFirstLetter() + "."
        return SuitabilityScore(value: rawScore, explanation: explanation)
    }
}

private extension String {
    func capitalizedFirstLetter() -> String {
        guard let first = self.first else { return self }
        return String(first).uppercased() + self.dropFirst()
    }
}
