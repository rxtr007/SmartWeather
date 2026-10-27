import Foundation

/// Deterministic scoring engine for outdoor sightseeing suitability.
/// Evaluates precipitation risk and volume, walking temperature comfort, and wind discomfort.
public struct OutdoorSightseeingScorer: Sendable {
    
    /// Evaluates daily weather metrics and returns a 0–100 suitability score with an explanation.
    public static func score(metrics: DailyWeatherMetrics) -> SuitabilityScore {
        var rawScore = 80 // Base comfortable outdoor expectation
        var explanationParts: [String] = []
        
        // 1. Precipitation penalties (rain is the primary impediment to walking/sightseeing)
        if metrics.precipitationSum >= 10.0 || metrics.precipitationProbabilityMax >= 80 {
            rawScore -= 55
            explanationParts.append("heavy rain expected (\(String(format: "%.1f", metrics.precipitationSum)) mm, \(metrics.precipitationProbabilityMax)%)")
        } else if metrics.precipitationSum >= 3.0 || metrics.precipitationProbabilityMax >= 50 {
            rawScore -= 35
            explanationParts.append("scattered rain likely (\(String(format: "%.1f", metrics.precipitationSum)) mm, \(metrics.precipitationProbabilityMax)%)")
        } else if metrics.precipitationSum >= 0.5 || metrics.precipitationProbabilityMax >= 25 {
            rawScore -= 15
            explanationParts.append("possible light showers (\(metrics.precipitationProbabilityMax)%)")
        } else {
            // Dry bonus only if temperature is not an extreme heatwave
            if metrics.temperatureMax <= 30.0 {
                rawScore += 10
            }
            explanationParts.append("dry conditions")
        }
        
        // 2. Temperature walking comfort
        if metrics.temperatureMax >= 18.0 && metrics.temperatureMax <= 24.0 {
            rawScore += 10
            explanationParts.append("ideal pleasant temperature (\(String(format: "%.0f", metrics.temperatureMax))°C)")
        } else if metrics.temperatureMax >= 14.0 && metrics.temperatureMax < 18.0 {
            explanationParts.append("mild temperature (\(String(format: "%.0f", metrics.temperatureMax))°C)")
        } else if metrics.temperatureMax >= 25.0 && metrics.temperatureMax <= 28.0 {
            explanationParts.append("warm weather (\(String(format: "%.0f", metrics.temperatureMax))°C)")
        } else if metrics.temperatureMax >= 8.0 && metrics.temperatureMax < 14.0 {
            rawScore -= 15
            explanationParts.append("cool brisk air (\(String(format: "%.0f", metrics.temperatureMax))°C)")
        } else if metrics.temperatureMax >= 0.0 && metrics.temperatureMax < 8.0 {
            rawScore -= 30
            explanationParts.append("cold temperatures (\(String(format: "%.0f", metrics.temperatureMax))°C)")
        } else if metrics.temperatureMax < 0.0 {
            rawScore -= 45
            explanationParts.append("freezing sub-zero temperatures (\(String(format: "%.0f", metrics.temperatureMax))°C)")
        } else if metrics.temperatureMax > 34.0 {
            rawScore -= 40
            explanationParts.append("sweltering heatwave (\(String(format: "%.0f", metrics.temperatureMax))°C)")
        } else if metrics.temperatureMax > 28.0 {
            rawScore -= 15
            explanationParts.append("hot temperatures (\(String(format: "%.0f", metrics.temperatureMax))°C)")
        }
        
        // 3. Wind discomfort
        if metrics.windSpeedMax > 45.0 {
            rawScore -= 30
            explanationParts.append("very strong winds (\(String(format: "%.0f", metrics.windSpeedMax)) km/h)")
        } else if metrics.windSpeedMax > 28.0 {
            rawScore -= 15
            explanationParts.append("gusty winds (\(String(format: "%.0f", metrics.windSpeedMax)) km/h)")
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
