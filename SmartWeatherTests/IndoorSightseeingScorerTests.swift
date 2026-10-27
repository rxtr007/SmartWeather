import Foundation

struct IndoorSightseeingScorerTests {
    static func run() {
        print("\n[IndoorSightseeingScorerTests]")
        testRainyColdDayIndoorAppeal()
        testExtremeHeatwaveIndoorAppeal()
        testPristineOutdoorDayDampener()
        testSevereStormTransitHazard()
    }
    
    static func testRainyColdDayIndoorAppeal() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 1.0,
            temperatureMax: 4.0, // Cold
            precipitationSum: 14.0, // Heavy rain
            precipitationProbabilityMax: 85,
            snowfallSum: 0.0,
            windSpeedMax: 15.0
        )
        
        let score = IndoorSightseeingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Indoor score should have numeric value")
            return
        }
        
        assertTrue(value >= 85, "Rainy, cold day should boost indoor score >= 85, got \(value)")
        assertEqual(score.status, SuitabilityStatus.suitable, "Indoor should be suitable on rainy cold days")
        assertTrue(score.explanation.lowercased().contains("rain") || score.explanation.lowercased().contains("cold"),
                   "Explanation should highlight rain or cold outdoor conditions")
    }
    
    static func testExtremeHeatwaveIndoorAppeal() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 25.0,
            temperatureMax: 36.0, // Sweltering heat
            precipitationSum: 0.0,
            precipitationProbabilityMax: 0,
            snowfallSum: 0.0,
            windSpeedMax: 12.0
        )
        
        let score = IndoorSightseeingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Indoor score should have numeric value")
            return
        }
        
        assertTrue(value >= 80, "Heatwave should boost indoor score >= 80, got \(value)")
        assertEqual(score.status, SuitabilityStatus.suitable, "Indoor should be suitable during heatwave")
        assertTrue(score.explanation.lowercased().contains("heat") || score.explanation.lowercased().contains("air-conditioned") || score.explanation.lowercased().contains("relief"),
                   "Explanation should highlight heat relief")
    }
    
    static func testPristineOutdoorDayDampener() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 15.0,
            temperatureMax: 22.0, // Perfect outdoor day
            precipitationSum: 0.0,
            precipitationProbabilityMax: 5,
            snowfallSum: 0.0,
            windSpeedMax: 10.0
        )
        
        let score = IndoorSightseeingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Indoor score should have numeric value")
            return
        }
        
        assertTrue(value >= 40 && value <= 65, "Pristine sunny day should yield marginal/fair indoor score (40-65), got \(value)")
        assertTrue(score.explanation.lowercased().contains("outdoor") || score.explanation.lowercased().contains("pleasant"),
                   "Explanation should mention pleasant outdoor alternative")
    }
    
    static func testSevereStormTransitHazard() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 10.0,
            temperatureMax: 14.0,
            precipitationSum: 48.0, // Torrential rain
            precipitationProbabilityMax: 100,
            snowfallSum: 0.0,
            windSpeedMax: 72.0      // Dangerous gale
        )
        
        let score = IndoorSightseeingScorer.score(metrics: metrics)
        guard let value = score.value else {
            assertTrue(false, "Indoor score should have numeric value")
            return
        }
        
        assertTrue(value < 40, "Dangerous storm hazards should penalize score to < 40, got \(value)")
        assertEqual(score.status, SuitabilityStatus.unsuitable, "Severe storm transit hazards make indoor sightseeing unsuitable")
        assertTrue(score.explanation.lowercased().contains("storm") || score.explanation.lowercased().contains("transit") || score.explanation.lowercased().contains("hazard"),
                   "Explanation should warn of travel or storm hazards")
    }
}
