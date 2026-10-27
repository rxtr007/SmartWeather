import Foundation
import Testing

@Suite("Indoor Sightseeing Scorer Tests")
struct IndoorSightseeingScorerTests {
    @Test("Rainy cold day boosts indoor appeal into suitable tier")
    func rainyColdDayIndoorAppeal() throws {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 1.0,
            temperatureMax: 4.0,
            precipitationSum: 14.0,
            precipitationProbabilityMax: 85,
            snowfallSum: 0.0,
            windSpeedMax: 15.0
        )
        
        let score = IndoorSightseeingScorer.score(metrics: metrics)
        let value = try #require(score.value)
        
        #expect(value >= 85)
        #expect(score.status == .suitable)
        #expect(score.explanation.lowercased().contains("rain") || score.explanation.lowercased().contains("cold"))
    }
    
    @Test("Extreme heatwave boosts air-conditioned indoor appeal")
    func extremeHeatwaveIndoorAppeal() throws {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 25.0,
            temperatureMax: 36.0,
            precipitationSum: 0.0,
            precipitationProbabilityMax: 0,
            snowfallSum: 0.0,
            windSpeedMax: 12.0
        )
        
        let score = IndoorSightseeingScorer.score(metrics: metrics)
        let value = try #require(score.value)
        
        #expect(value >= 80)
        #expect(score.status == .suitable)
        #expect(score.explanation.lowercased().contains("heat") || score.explanation.lowercased().contains("air-conditioned") || score.explanation.lowercased().contains("relief"))
    }
    
    @Test("Pristine outdoor day dampens indoor appeal to fair/marginal")
    func pristineOutdoorDayDampener() throws {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 15.0,
            temperatureMax: 22.0,
            precipitationSum: 0.0,
            precipitationProbabilityMax: 5,
            snowfallSum: 0.0,
            windSpeedMax: 10.0
        )
        
        let score = IndoorSightseeingScorer.score(metrics: metrics)
        let value = try #require(score.value)
        
        #expect(value >= 40 && value <= 65)
        #expect(score.explanation.lowercased().contains("outdoor") || score.explanation.lowercased().contains("pleasant"))
    }
    
    @Test("Severe storm transit hazard safeguards indoor sightseeing to unsuitable")
    func severeStormTransitHazard() throws {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 10.0,
            temperatureMax: 14.0,
            precipitationSum: 48.0,
            precipitationProbabilityMax: 100,
            snowfallSum: 0.0,
            windSpeedMax: 72.0
        )
        
        let score = IndoorSightseeingScorer.score(metrics: metrics)
        let value = try #require(score.value)
        
        #expect(value < 40)
        #expect(score.status == .unsuitable)
        #expect(score.explanation.lowercased().contains("storm") || score.explanation.lowercased().contains("transit") || score.explanation.lowercased().contains("hazard"))
    }
}
