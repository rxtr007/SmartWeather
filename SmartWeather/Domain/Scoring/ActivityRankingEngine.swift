import Foundation

/// Represents a ranked forecast day for a specific activity.
public struct RankedDay: Sendable, Equatable, Hashable, Identifiable {
    public var id: Date { assessment.date }
    public let rank: Int
    public let assessment: DailyAssessment
    public let score: SuitabilityScore
    
    public init(rank: Int, assessment: DailyAssessment, score: SuitabilityScore) {
        self.rank = rank
        self.assessment = assessment
        self.score = score
    }
}

/// Deterministic ranking engine that orders forecast days for an activity.
public struct ActivityRankingEngine: Sendable {
    
    /// Ranks daily assessments for a specific activity, applying clear deterministic tie-breaking.
    public static func rank(assessments: [DailyAssessment], for activity: ActivityType) -> [RankedDay] {
        let sorted = assessments.sorted { lhs, rhs in
            let scoreL = lhs.score(for: activity)
            let scoreR = rhs.score(for: activity)
            
            // 1. Available scores always rank ahead of unavailable scores
            if scoreL.value == nil && scoreR.value != nil {
                return false
            }
            if scoreL.value != nil && scoreR.value == nil {
                return true
            }
            if let valL = scoreL.value, let valR = scoreR.value, valL != valR {
                return valL > valR
            }
            
            // 2. Tie-breaker 1: Lower precipitation probability
            if lhs.metrics.precipitationProbabilityMax != rhs.metrics.precipitationProbabilityMax {
                return lhs.metrics.precipitationProbabilityMax < rhs.metrics.precipitationProbabilityMax
            }
            
            // 3. Tie-breaker 2: Lower precipitation volume
            if lhs.metrics.precipitationSum != rhs.metrics.precipitationSum {
                return lhs.metrics.precipitationSum < rhs.metrics.precipitationSum
            }
            
            // 4. Tie-breaker 3: Lower wind speed
            if lhs.metrics.windSpeedMax != rhs.metrics.windSpeedMax {
                return lhs.metrics.windSpeedMax < rhs.metrics.windSpeedMax
            }
            
            // 5. Tie-breaker 4: Chronological order (earlier date first)
            return lhs.date < rhs.date
        }
        
        return sorted.enumerated().map { index, assessment in
            RankedDay(rank: index + 1, assessment: assessment, score: assessment.score(for: activity))
        }
    }
}
