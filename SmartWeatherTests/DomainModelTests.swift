import Foundation
import Testing

@Suite("Domain Model Tests")
struct DomainModelTests {
    @Test("All 4 activity types are present with valid display names and symbols")
    func activityTypeEnum() {
        let allCases = ActivityType.allCases
        #expect(allCases.count == 4)
        
        #expect(ActivityType.skiing.displayName == "Skiing")
        #expect(ActivityType.surfing.displayName == "Surfing")
        #expect(ActivityType.outdoorSightseeing.displayName == "Outdoor Sightseeing")
        #expect(ActivityType.indoorSightseeing.displayName == "Indoor Sightseeing")
        
        for activity in allCases {
            #expect(!activity.displayName.isEmpty)
            #expect(!activity.symbolName.isEmpty)
        }
    }
    
    @Test("DailyWeatherMetrics preserves all initialized properties")
    func dailyWeatherMetricsInitialization() {
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
        
        #expect(metrics.date == date)
        #expect(metrics.temperatureMin == -5.0)
        #expect(metrics.temperatureMax == 1.5)
        #expect(metrics.precipitationSum == 2.0)
        #expect(metrics.precipitationProbabilityMax == 30)
        #expect(metrics.snowfallSum == 8.0)
        #expect(metrics.windSpeedMax == 18.0)
        #expect(metrics.waveHeightMax == nil)
        #expect(metrics.wavePeriodMax == nil)
    }
    
    @Test("SuitabilityScore classifies scores into suitable, marginal, and unsuitable brackets")
    func suitabilityScoreCategories() {
        let high = SuitabilityScore(value: 85, explanation: "Great snow conditions")
        #expect(high.status == .suitable)
        #expect(high.value == 85)
        
        let medium = SuitabilityScore(value: 55, explanation: "Moderate conditions")
        #expect(medium.status == .marginal)
        
        let low = SuitabilityScore(value: 20, explanation: "Poor conditions")
        #expect(low.status == .unsuitable)
        
        // Clamping check: values should be clamped between 0 and 100
        let over = SuitabilityScore(value: 120, explanation: "Over limit")
        #expect(over.value == 100)
        
        let under = SuitabilityScore(value: -15, explanation: "Under limit")
        #expect(under.value == 0)
    }
    
    @Test("SuitabilityScore represents unavailable activity with explicit reason")
    func suitabilityScoreUnavailable() {
        let unavailable = SuitabilityScore.unavailable(reason: "Inland location lacks wave data")
        #expect(unavailable.status == .unavailable(reason: "Inland location lacks wave data"))
        #expect(unavailable.value == nil)
        #expect(unavailable.explanation == "Inland location lacks wave data")
    }
}
