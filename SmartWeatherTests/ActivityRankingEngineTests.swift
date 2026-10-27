import Foundation
import Testing

@Suite("Activity Ranking Engine Tests")
struct ActivityRankingEngineTests {
    @Test("DailyAssessment evaluates scores for all supported activities")
    func dailyAssessmentEvaluation() {
        let metrics = DailyWeatherMetrics(
            date: Date(timeIntervalSince1970: 1730000000),
            temperatureMin: -5.0,
            temperatureMax: -2.0,
            precipitationSum: 10.0,
            precipitationProbabilityMax: 80,
            snowfallSum: 12.0,
            windSpeedMax: 15.0
        )
        
        let assessment = DailyAssessment(metrics: metrics)
        #expect(assessment.date == metrics.date)
        
        let skiScore = assessment.score(for: .skiing)
        #expect(skiScore.value != nil)
        #expect(skiScore.status == .suitable)
        
        let surfScore = assessment.score(for: .surfing)
        #expect(surfScore.status == .unavailable(reason: "Marine wave data is unavailable for inland locations"))
    }
    
    @Test("Ranks 7-day assessments in descending order of activity suitability score")
    func rankingByScoreDescending() throws {
        let baseDate = Date(timeIntervalSince1970: 1730000000)
        
        // Day 1: Marginal ski day (50)
        let day1 = DailyAssessment(metrics: DailyWeatherMetrics(
            date: baseDate,
            temperatureMin: -4.0, temperatureMax: -1.0,
            precipitationSum: 0.0, precipitationProbabilityMax: 10,
            snowfallSum: 0.0, windSpeedMax: 12.0
        ))
        
        // Day 2: Ideal powder ski day (90)
        let day2 = DailyAssessment(metrics: DailyWeatherMetrics(
            date: baseDate.addingTimeInterval(86400),
            temperatureMin: -8.0, temperatureMax: -3.0,
            precipitationSum: 15.0, precipitationProbabilityMax: 80,
            snowfallSum: 18.0, windSpeedMax: 15.0
        ))
        
        // Day 3: Warm slush ski day (0)
        let day3 = DailyAssessment(metrics: DailyWeatherMetrics(
            date: baseDate.addingTimeInterval(172800),
            temperatureMin: 3.0, temperatureMax: 8.0,
            precipitationSum: 12.0, precipitationProbabilityMax: 90,
            snowfallSum: 0.0, windSpeedMax: 20.0
        ))
        
        let ranked = ActivityRankingEngine.rank(assessments: [day1, day2, day3], for: .skiing)
        #expect(ranked.count == 3)
        let r0 = try #require(ranked.indices.contains(0) ? ranked[0] : nil)
        let r1 = try #require(ranked.indices.contains(1) ? ranked[1] : nil)
        let r2 = try #require(ranked.indices.contains(2) ? ranked[2] : nil)
        
        #expect(r0.assessment.date == day2.date)
        #expect(r0.rank == 1)
        
        #expect(r1.assessment.date == day1.date)
        #expect(r1.rank == 2)
        
        #expect(r2.assessment.date == day3.date)
        #expect(r2.rank == 3)
    }
    
    @Test("Breaks equal score ties deterministically by lower rain risk")
    func deterministicTieBreaking() throws {
        let baseDate = Date(timeIntervalSince1970: 1730000000)
        
        // Both days receive score 75 for outdoor sightseeing, but Day A has 20% rain chance, Day B has 5%
        let dayA = DailyAssessment(metrics: DailyWeatherMetrics(
            date: baseDate,
            temperatureMin: 6.0, temperatureMax: 11.0,
            precipitationSum: 0.0, precipitationProbabilityMax: 20,
            snowfallSum: 0.0, windSpeedMax: 15.0
        ))
        
        let dayB = DailyAssessment(metrics: DailyWeatherMetrics(
            date: baseDate.addingTimeInterval(86400),
            temperatureMin: 6.0, temperatureMax: 11.0,
            precipitationSum: 0.0, precipitationProbabilityMax: 5,
            snowfallSum: 0.0, windSpeedMax: 15.0
        ))
        
        let ranked = ActivityRankingEngine.rank(assessments: [dayA, dayB], for: .outdoorSightseeing)
        #expect(ranked.count == 2)
        let r0 = try #require(ranked.indices.contains(0) ? ranked[0] : nil)
        let r1 = try #require(ranked.indices.contains(1) ? ranked[1] : nil)
        
        #expect(r0.assessment.date == dayB.date)
        #expect(r1.assessment.date == dayA.date)
    }
    
    @Test("Unavailable scores are safely sorted to the end of rankings")
    func unavailableScoresSortedLast() throws {
        let baseDate = Date(timeIntervalSince1970: 1730000000)
        
        // Day 1: Has wave data (score 100)
        let day1 = DailyAssessment(metrics: DailyWeatherMetrics(
            date: baseDate,
            temperatureMin: 18.0, temperatureMax: 24.0,
            precipitationSum: 0.0, precipitationProbabilityMax: 10,
            snowfallSum: 0.0, windSpeedMax: 10.0,
            waveHeightMax: 1.8, wavePeriodMax: 13.0
        ))
        
        // Day 2: Has no wave data (.unavailable)
        let day2 = DailyAssessment(metrics: DailyWeatherMetrics(
            date: baseDate.addingTimeInterval(86400),
            temperatureMin: 18.0, temperatureMax: 24.0,
            precipitationSum: 0.0, precipitationProbabilityMax: 10,
            snowfallSum: 0.0, windSpeedMax: 10.0,
            waveHeightMax: nil, wavePeriodMax: nil
        ))
        
        let ranked = ActivityRankingEngine.rank(assessments: [day2, day1], for: .surfing)
        #expect(ranked.count == 2)
        let r0 = try #require(ranked.indices.contains(0) ? ranked[0] : nil)
        let r1 = try #require(ranked.indices.contains(1) ? ranked[1] : nil)
        
        #expect(r0.assessment.date == day1.date)
        #expect(r1.assessment.date == day2.date)
        #expect(r1.score.status == .unavailable(reason: "Marine wave data is unavailable for inland locations"))
    }
}
