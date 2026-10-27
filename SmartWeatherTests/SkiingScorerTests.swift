import Foundation

struct SkiingScorerTests {
    static func run() {
        print("\n[SkiingScorerTests]")
        testIdealPowderDay()
        testColdGroomedSnowDay()
        testWarmRainSlushDay()
        testHighWindLiftClosureDay()
    }
    
    static func testIdealPowderDay() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: -8.0,
            temperatureMax: -3.0,
            precipitationSum: 15.0,
            precipitationProbabilityMax: 80,
            snowfallSum: 18.0,
            windSpeedMax: 15.0
        )
        
        let score = SkiingScorer.score(metrics: metrics)
        assertTrue(score.value != nil, "Score value should be present")
        guard let value = score.value else { return }
        
        assertTrue(value >= 80, "Ideal powder day should score >= 80, got \(value)")
        assertEqual(score.status, SuitabilityStatus.suitable, "Ideal day should be suitable")
        assertTrue(score.explanation.lowercased().contains("powder") || score.explanation.lowercased().contains("snow"),
                   "Explanation should highlight snowfall")
    }
    
    static func testColdGroomedSnowDay() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: -6.0,
            temperatureMax: -2.0,
            precipitationSum: 0.0,
            precipitationProbabilityMax: 10,
            snowfallSum: 0.0,
            windSpeedMax: 12.0
        )
        
        let score = SkiingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Score value should be present")
            return
        }
        
        assertTrue(value >= 35 && value <= 65, "Cold day with no fresh snow should score marginal (35-65), got \(value)")
        assertEqual(score.status, SuitabilityStatus.marginal, "Status should be marginal without fresh snow")
    }
    
    static func testWarmRainSlushDay() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 3.0,
            temperatureMax: 8.0,
            precipitationSum: 12.0,
            precipitationProbabilityMax: 90,
            snowfallSum: 0.0,
            windSpeedMax: 22.0
        )
        
        let score = SkiingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Score value should be present")
            return
        }
        
        assertTrue(value < 30, "Warm rainy day should score < 30, got \(value)")
        assertEqual(score.status, SuitabilityStatus.unsuitable, "Warm rainy day should be unsuitable")
        assertTrue(score.explanation.lowercased().contains("rain") || score.explanation.lowercased().contains("warm") || score.explanation.lowercased().contains("slush"),
                   "Explanation should explain rain or above-freezing thaw")
    }
    
    static func testHighWindLiftClosureDay() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: -10.0,
            temperatureMax: -5.0,
            precipitationSum: 20.0,
            precipitationProbabilityMax: 95,
            snowfallSum: 25.0,
            windSpeedMax: 65.0 // Severe gale wind
        )
        
        let score = SkiingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Score value should be present")
            return
        }
        
        assertTrue(value < 65, "Gale winds (>60 km/h) should penalize score to < 65 due to lift closures, got \(value)")
        assertTrue(score.explanation.lowercased().contains("wind"), "Explanation should warn about strong winds")
    }
}
