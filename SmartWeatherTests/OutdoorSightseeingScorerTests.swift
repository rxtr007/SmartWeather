import Foundation

struct OutdoorSightseeingScorerTests {
    static func run() {
        print("\n[OutdoorSightseeingScorerTests]")
        testIdealMildSunnyDay()
        testCoolAutumnDay()
        testHeavyRainstormDay()
        testExtremeHeatwaveDay()
    }
    
    static func testIdealMildSunnyDay() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 14.0,
            temperatureMax: 22.0,
            precipitationSum: 0.0,
            precipitationProbabilityMax: 5,
            snowfallSum: 0.0,
            windSpeedMax: 10.0
        )
        
        let score = OutdoorSightseeingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Outdoor score should have numeric value")
            return
        }
        
        assertTrue(value >= 90, "Ideal sunny day should score >= 90, got \(value)")
        assertEqual(score.status, SuitabilityStatus.suitable, "Ideal day should be suitable")
        assertTrue(score.explanation.lowercased().contains("pleasant") || score.explanation.lowercased().contains("ideal") || score.explanation.lowercased().contains("comfortable"),
                   "Explanation should highlight comfortable weather")
    }
    
    static func testCoolAutumnDay() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 6.0,
            temperatureMax: 11.0,
            precipitationSum: 0.0,
            precipitationProbabilityMax: 15,
            snowfallSum: 0.0,
            windSpeedMax: 16.0
        )
        
        let score = OutdoorSightseeingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Outdoor score should have numeric value")
            return
        }
        
        assertTrue(value >= 55 && value <= 75, "Cool dry day should score marginal/good (55-75), got \(value)")
        assertTrue(score.explanation.lowercased().contains("cool") || score.explanation.lowercased().contains("brisk"),
                   "Explanation should describe cool temperatures")
    }
    
    static func testHeavyRainstormDay() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 12.0,
            temperatureMax: 16.0,
            precipitationSum: 18.0, // Heavy rain
            precipitationProbabilityMax: 95,
            snowfallSum: 0.0,
            windSpeedMax: 38.0      // Gusty
        )
        
        let score = OutdoorSightseeingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Outdoor score should have numeric value")
            return
        }
        
        assertTrue(value < 30, "Heavy rainstorm should score < 30, got \(value)")
        assertEqual(score.status, SuitabilityStatus.unsuitable, "Rainstorm should be unsuitable for outdoor sightseeing")
        assertTrue(score.explanation.lowercased().contains("rain"), "Explanation should note rain")
    }
    
    static func testExtremeHeatwaveDay() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 26.0,
            temperatureMax: 37.0, // Heatwave
            precipitationSum: 0.0,
            precipitationProbabilityMax: 5,
            snowfallSum: 0.0,
            windSpeedMax: 12.0
        )
        
        let score = OutdoorSightseeingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Outdoor score should have numeric value")
            return
        }
        
        assertTrue(value < 50, "Extreme 37°C heatwave should score < 50, got \(value)")
        assertTrue(score.explanation.lowercased().contains("heat") || score.explanation.lowercased().contains("hot"),
                   "Explanation should warn of extreme heat")
    }
}
