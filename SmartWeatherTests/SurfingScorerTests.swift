import Foundation

struct SurfingScorerTests {
    static func run() {
        print("\n[SurfingScorerTests]")
        testIdealGroundswell()
        testFlatSummerConditions()
        testBlownOutWindswell()
        testInlandMissingMarineData()
    }
    
    static func testIdealGroundswell() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 18.0,
            temperatureMax: 24.0,
            precipitationSum: 0.0,
            precipitationProbabilityMax: 10,
            snowfallSum: 0.0,
            windSpeedMax: 10.0,
            waveHeightMax: 1.8,
            wavePeriodMax: 13.0
        )
        
        let score = SurfingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Ideal surf should have a numeric score")
            return
        }
        
        assertTrue(value >= 80, "Ideal 1.8m groundswell with light wind should score >= 80, got \(value)")
        assertEqual(score.status, SuitabilityStatus.suitable, "Ideal surf should be suitable")
        assertTrue(score.explanation.lowercased().contains("swell") || score.explanation.lowercased().contains("wave"),
                   "Explanation should mention swell/waves")
    }
    
    static func testFlatSummerConditions() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 20.0,
            temperatureMax: 26.0,
            precipitationSum: 0.0,
            precipitationProbabilityMax: 5,
            snowfallSum: 0.0,
            windSpeedMax: 8.0,
            waveHeightMax: 0.3,
            wavePeriodMax: 5.0
        )
        
        let score = SurfingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Flat conditions should have a numeric score")
            return
        }
        
        assertTrue(value <= 20, "Flat 0.3m wave should score <= 20, got \(value)")
        assertEqual(score.status, SuitabilityStatus.unsuitable, "Flat surf should be unsuitable")
        assertTrue(score.explanation.lowercased().contains("flat") || score.explanation.lowercased().contains("small"),
                   "Explanation should describe flat/small waves")
    }
    
    static func testBlownOutWindswell() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 15.0,
            temperatureMax: 19.0,
            precipitationSum: 4.0,
            precipitationProbabilityMax: 60,
            snowfallSum: 0.0,
            windSpeedMax: 42.0, // High wind
            waveHeightMax: 2.2,
            wavePeriodMax: 7.0  // Short period
        )
        
        let score = SurfingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Blown-out conditions should have a numeric score")
            return
        }
        
        assertTrue(value < 40, "Blown out 42 km/h wind with short period should score < 40, got \(value)")
        assertEqual(score.status, SuitabilityStatus.unsuitable, "Blown out surf should be unsuitable")
        assertTrue(score.explanation.lowercased().contains("wind") || score.explanation.lowercased().contains("chop"),
                   "Explanation should describe wind or chop")
    }
    
    static func testInlandMissingMarineData() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 12.0,
            temperatureMax: 22.0,
            precipitationSum: 0.0,
            precipitationProbabilityMax: 0,
            snowfallSum: 0.0,
            windSpeedMax: 10.0,
            waveHeightMax: nil, // Inland location
            wavePeriodMax: nil  // Inland location
        )
        
        let score = SurfingScorer.score(metrics: metrics)
        assertTrue(score.value == nil, "Inland surf score must be nil")
        assertEqual(score.status,
                    SuitabilityStatus.unavailable(reason: "Marine wave data is unavailable for inland locations"),
                    "Inland surf status must be unavailable")
        assertTrue(score.explanation.contains("unavailable"), "Explanation should state data is unavailable")
    }
}
