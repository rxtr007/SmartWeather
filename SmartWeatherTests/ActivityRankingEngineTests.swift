import Foundation

struct ActivityRankingEngineTests {
    static func run() {
        print("\n[ActivityRankingEngineTests]")
        testDailyAssessmentEvaluation()
        testRankingByScoreDescending()
        testDeterministicTieBreaking()
        testUnavailableScoresSortedLast()
    }
    
    static func testDailyAssessmentEvaluation() {
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
        assertEqual(assessment.date, metrics.date, "Assessment date should match metrics date")
        
        let skiScore = assessment.score(for: .skiing)
        assertTrue(skiScore.value != nil, "Skiing score should be calculated")
        assertEqual(skiScore.status, SuitabilityStatus.suitable, "Snow day should be suitable for skiing")
        
        let surfScore = assessment.score(for: .surfing)
        assertEqual(surfScore.status,
                    SuitabilityStatus.unavailable(reason: "Marine wave data is unavailable for inland locations"),
                    "Inland surfing should be unavailable")
    }
    
    static func testRankingByScoreDescending() {
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
        assertEqual(ranked.count, 3, "All 3 days should be ranked")
        
        // Expected order: Day 2 (best), Day 1 (second), Day 3 (worst)
        assertEqual(ranked[0].assessment.date, day2.date, "Rank 1 should be Day 2")
        assertEqual(ranked[0].rank, 1, "Rank 1 index")
        
        assertEqual(ranked[1].assessment.date, day1.date, "Rank 2 should be Day 1")
        assertEqual(ranked[1].rank, 2, "Rank 2 index")
        
        assertEqual(ranked[2].assessment.date, day3.date, "Rank 3 should be Day 3")
        assertEqual(ranked[2].rank, 3, "Rank 3 index")
    }
    
    static func testDeterministicTieBreaking() {
        let baseDate = Date(timeIntervalSince1970: 1730000000)
        
        // Both days will receive score 75 for outdoor sightseeing, but Day A has 20% rain chance, Day B has 5%
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
        assertEqual(ranked.count, 2, "Both days should be ranked")
        
        // Day B has lower precipitation risk, so it breaks the tie and takes rank 1
        assertEqual(ranked[0].assessment.date, dayB.date, "Day B with lower rain risk should take Rank 1")
        assertEqual(ranked[1].assessment.date, dayA.date, "Day A should take Rank 2")
    }
    
    static func testUnavailableScoresSortedLast() {
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
        assertEqual(ranked[0].assessment.date, day1.date, "Day with valid surf data should rank first")
        assertEqual(ranked[1].assessment.date, day2.date, "Unavailable surf day should be placed last")
        assertEqual(ranked[1].score.status,
                    SuitabilityStatus.unavailable(reason: "Marine wave data is unavailable for inland locations"),
                    "Unavailable status preserved")
    }
}
