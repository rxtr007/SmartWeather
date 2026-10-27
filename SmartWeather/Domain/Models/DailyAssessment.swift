import Foundation

/// Represents an aggregated daily forecast assessment containing raw weather metrics
/// and precomputed suitability scores for all four activities.
public struct DailyAssessment: Sendable, Equatable, Hashable, Identifiable {
    public var id: Date { date }
    public let date: Date
    public let metrics: DailyWeatherMetrics
    public let scores: [ActivityType: SuitabilityScore]
    
    public init(metrics: DailyWeatherMetrics) {
        self.date = metrics.date
        self.metrics = metrics
        
        var evaluatedScores: [ActivityType: SuitabilityScore] = [:]
        evaluatedScores[.skiing] = SkiingScorer.score(metrics: metrics)
        evaluatedScores[.surfing] = SurfingScorer.score(metrics: metrics)
        evaluatedScores[.outdoorSightseeing] = OutdoorSightseeingScorer.score(metrics: metrics)
        evaluatedScores[.indoorSightseeing] = IndoorSightseeingScorer.score(metrics: metrics)
        self.scores = evaluatedScores
    }
    
    /// Returns the suitability score for a given activity.
    public func score(for activity: ActivityType) -> SuitabilityScore {
        scores[activity] ?? SuitabilityScore.unavailable(reason: "Score unavailable")
    }
}
