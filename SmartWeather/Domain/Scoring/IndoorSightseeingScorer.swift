import Foundation

/// Deterministic scoring engine for indoor sightseeing suitability (museums, galleries, aquariums).
/// Balances indoor appeal during inclement outdoor weather against travel and transit feasibility.
public struct IndoorSightseeingScorer: Sendable {
    
    /// Evaluates daily weather metrics and returns a 0–100 suitability score with an explanation.
    public static func score(metrics: DailyWeatherMetrics) -> SuitabilityScore {
        var rawScore = 60 // Baseline appeal for indoor cultural attractions
        var explanationParts: [String] = []
        
        let isSevereHazard = metrics.precipitationSum >= 35.0 || metrics.windSpeedMax >= 65.0
        
        if isSevereHazard {
            // Severe storms (torrential rain or gale winds) make transit dangerous
            rawScore -= 45
            explanationParts.append("severe storm hazards make travel and transit to venues hazardous")
        } else {
            // 1. Inclement weather appeal boosts (safe to travel)
            if metrics.precipitationSum >= 10.0 || metrics.precipitationProbabilityMax >= 75 {
                rawScore += 25
                explanationParts.append("rainy outdoor weather makes indoor venues an appealing refuge")
            } else if metrics.precipitationSum >= 2.5 || metrics.precipitationProbabilityMax >= 40 {
                rawScore += 15
                explanationParts.append("passing showers favor indoor exploration")
            }
            
            // Temperature drivers
            if metrics.temperatureMax < 0.0 {
                rawScore += 20
                explanationParts.append("heated indoor exhibits provide comfort from freezing outdoor temperatures")
            } else if metrics.temperatureMax < 6.0 {
                rawScore += 15
                explanationParts.append("cold weather encourages indoor activities")
            } else if metrics.temperatureMax > 33.0 {
                rawScore += 20
                explanationParts.append("air-conditioned indoor venues offer relief from sweltering heat")
            }
            
            // 2. Pristine outdoor weather dampener
            let isPristineOutdoor = metrics.temperatureMax >= 18.0 &&
                                    metrics.temperatureMax <= 25.0 &&
                                    metrics.precipitationSum < 1.0 &&
                                    metrics.precipitationProbabilityMax < 20 &&
                                    metrics.windSpeedMax < 20.0
            if isPristineOutdoor {
                rawScore -= 15
                explanationParts.append("pleasant sunny weather may tempt visitors outdoors, though venues remain accessible")
            }
            
            // 3. Moderate wind penalty
            if metrics.windSpeedMax >= 45.0 {
                rawScore -= 15
                explanationParts.append("gusty winds affect travel comfort")
            }
        }
        
        if explanationParts.isEmpty {
            explanationParts.append("standard comfortable conditions for indoor attractions")
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
