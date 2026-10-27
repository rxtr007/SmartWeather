import Foundation

struct DomainModelTests {
    static func run() {
        print("\n[DomainModelTests]")
        testActivityTypeEnum()
        testDailyWeatherMetricsInitialization()
        testSuitabilityScoreCategories()
        testSuitabilityScoreUnavailable()
    }
    
    static func testActivityTypeEnum() {
        let allCases = ActivityType.allCases
        assertEqual(allCases.count, 4, "Should have exactly 4 activity types")
        
        assertEqual(ActivityType.skiing.displayName, "Skiing")
        assertEqual(ActivityType.surfing.displayName, "Surfing")
        assertEqual(ActivityType.outdoorSightseeing.displayName, "Outdoor Sightseeing")
        assertEqual(ActivityType.indoorSightseeing.displayName, "Indoor Sightseeing")
        
        assertTrue(!ActivityType.skiing.symbolName.isEmpty, "Skiing should have SF symbol")
        assertTrue(!ActivityType.surfing.symbolName.isEmpty, "Surfing should have SF symbol")
    }
    
    static func testDailyWeatherMetricsInitialization() {
        let date = Date(timeIntervalSince1970: 1730000000)
        let metrics = DailyWeatherMetrics(
            date: date,
            temperatureMin: -5.0,
            temperatureMax: 1.5,
            precipitationSum: 2.0,
            precipitationProbabilityMax: 30,
            snowfallSum: 8.0,
            windSpeedMax: 18.0,
            waveHeightMax: nil,
            wavePeriodMax: nil
        )
        
        assertEqual(metrics.date, date, "Date should match")
        assertEqual(metrics.temperatureMin, -5.0, "temperatureMin should match")
        assertEqual(metrics.temperatureMax, 1.5, "temperatureMax should match")
        assertEqual(metrics.precipitationSum, 2.0, "precipitationSum should match")
        assertEqual(metrics.precipitationProbabilityMax, 30, "precipitationProbabilityMax should match")
        assertEqual(metrics.snowfallSum, 8.0, "snowfallSum should match")
        assertEqual(metrics.windSpeedMax, 18.0, "windSpeedMax should match")
        assertTrue(metrics.waveHeightMax == nil, "waveHeightMax should be nil for inland")
        assertTrue(metrics.wavePeriodMax == nil, "wavePeriodMax should be nil for inland")
    }
    
    static func testSuitabilityScoreCategories() {
        let high = SuitabilityScore(value: 85, explanation: "Great snow conditions")
        assertEqual(high.status, .suitable, "Score >= 70 should be suitable")
        assertEqual(high.value, 85, "Score value should be 85")
        
        let medium = SuitabilityScore(value: 55, explanation: "Moderate conditions")
        assertEqual(medium.status, .marginal, "Score 40-69 should be marginal")
        
        let low = SuitabilityScore(value: 20, explanation: "Poor conditions")
        assertEqual(low.status, .unsuitable, "Score < 40 should be unsuitable")
        
        // Clamping check: values should be clamped between 0 and 100
        let over = SuitabilityScore(value: 120, explanation: "Over limit")
        assertEqual(over.value, 100, "Score should clamp to 100")
        
        let under = SuitabilityScore(value: -15, explanation: "Under limit")
        assertEqual(under.value, 0, "Score should clamp to 0")
    }
    
    static func testSuitabilityScoreUnavailable() {
        let unavailable = SuitabilityScore.unavailable(reason: "Inland location lacks wave data")
        assertEqual(unavailable.status, .unavailable(reason: "Inland location lacks wave data"), "Should be unavailable status")
        assertTrue(unavailable.value == nil, "Unavailable score should have nil value")
        assertEqual(unavailable.explanation, "Inland location lacks wave data", "Explanation should match reason")
    }
}
