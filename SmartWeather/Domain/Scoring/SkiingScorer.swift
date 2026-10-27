import Foundation

/// Deterministic scoring engine for skiing suitability.
/// Evaluates snow conditions, mountain temperatures, rain risk, and wind hazards.
public struct SkiingScorer: Sendable {
    
    /// Evaluates daily weather metrics and returns a 0–100 suitability score with an explanation.
    public static func score(metrics: DailyWeatherMetrics) -> SuitabilityScore {
        var rawScore = 0
        var explanationParts: [String] = []
        
        // 1. Snowfall base evaluation
        if metrics.snowfallSum >= 15.0 {
            rawScore += 65
            explanationParts.append("Excellent fresh powder snowfall (\(String(format: "%.1f", metrics.snowfallSum)) cm)")
        } else if metrics.snowfallSum >= 8.0 {
            rawScore += 55
            explanationParts.append("Good fresh snowfall (\(String(format: "%.1f", metrics.snowfallSum)) cm)")
        } else if metrics.snowfallSum >= 3.0 {
            rawScore += 40
            explanationParts.append("Light fresh snow (\(String(format: "%.1f", metrics.snowfallSum)) cm)")
        } else if metrics.snowfallSum > 0.0 {
            rawScore += 30
            explanationParts.append("Dusting of fresh snow (\(String(format: "%.1f", metrics.snowfallSum)) cm)")
        } else {
            if metrics.temperatureMax <= 0.0 {
                rawScore += 25
                explanationParts.append("Preserved groomed snowpack, but no fresh snowfall")
            } else {
                rawScore += 10
                explanationParts.append("No fresh snowfall with thawing conditions")
            }
        }
        
        // 2. Temperature sweet spots and penalties
        if metrics.temperatureMax >= -8.0 && metrics.temperatureMax <= -2.0 {
            rawScore += 25
            explanationParts.append("ideal cold temperatures (\(String(format: "%.0f", metrics.temperatureMax))°C)")
        } else if (metrics.temperatureMax >= -14.0 && metrics.temperatureMax < -8.0) ||
                  (metrics.temperatureMax > -2.0 && metrics.temperatureMax <= 0.0) {
            rawScore += 15
            explanationParts.append("tolerable freezing temperatures")
        } else if metrics.temperatureMax > 4.0 {
            rawScore -= 35
            explanationParts.append("warm temperatures (\(String(format: "%.0f", metrics.temperatureMax))°C) causing slush")
        } else if metrics.temperatureMax > 0.0 {
            rawScore -= 15
            explanationParts.append("temperatures slightly above freezing")
        }
        
        if metrics.temperatureMin < -20.0 {
            rawScore -= 15
            explanationParts.append("severe frostbite hazard (\(String(format: "%.0f", metrics.temperatureMin))°C minimum)")
        }
        
        // 3. Liquid rain penalty (rain on snow causes severe deterioration)
        let isLikelyRain = metrics.temperatureMax > 0.0 && metrics.precipitationSum > metrics.snowfallSum
        if isLikelyRain {
            if metrics.precipitationSum > 5.0 {
                rawScore -= 40
                explanationParts.append("heavy rain degrading snow conditions")
            } else if metrics.precipitationSum > 0.0 {
                rawScore -= 20
                explanationParts.append("light rain dampening snow surface")
            }
        }
        
        // 4. Wind penalty (lift closures and windchill)
        if metrics.windSpeedMax > 55.0 {
            rawScore -= 35
            explanationParts.append("severe gale winds (\(String(format: "%.0f", metrics.windSpeedMax)) km/h) risking chairlift closures")
        } else if metrics.windSpeedMax > 35.0 {
            rawScore -= 15
            explanationParts.append("gusty winds affecting summit lifts")
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
