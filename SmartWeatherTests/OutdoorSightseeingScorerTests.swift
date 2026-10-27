import Foundation
import Testing

@Suite("Outdoor Sightseeing Scorer Tests")
struct OutdoorSightseeingScorerTests {
    @Test("Ideal mild sunny day scores in suitable tier")
    func idealMildSunnyDay() throws {
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
        let value = try #require(score.value)
        
        #expect(value >= 90)
        #expect(score.status == .suitable)
        #expect(score.explanation.lowercased().contains("pleasant") || score.explanation.lowercased().contains("ideal") || score.explanation.lowercased().contains("comfortable"))
    }
    
    @Test("Cool autumn day scores marginal to good")
    func coolAutumnDay() throws {
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
        let value = try #require(score.value)
        
        #expect(value >= 55 && value <= 75)
        #expect(score.explanation.lowercased().contains("cool") || score.explanation.lowercased().contains("brisk"))
    }
    
    @Test("Heavy rainstorm scores unsuitable")
    func heavyRainstormDay() throws {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 12.0,
            temperatureMax: 16.0,
            precipitationSum: 18.0,
            precipitationProbabilityMax: 95,
            snowfallSum: 0.0,
            windSpeedMax: 38.0
        )
        
        let score = OutdoorSightseeingScorer.score(metrics: metrics)
        let value = try #require(score.value)
        
        #expect(value < 30)
        #expect(score.status == .unsuitable)
        #expect(score.explanation.lowercased().contains("rain"))
    }
    
    @Test("Extreme heatwave scores penalized due to heat stress")
    func extremeHeatwaveDay() throws {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 26.0,
            temperatureMax: 37.0,
            precipitationSum: 0.0,
            precipitationProbabilityMax: 5,
            snowfallSum: 0.0,
            windSpeedMax: 12.0
        )
        
        let score = OutdoorSightseeingScorer.score(metrics: metrics)
        let value = try #require(score.value)
        
        #expect(value < 50)
        #expect(score.explanation.lowercased().contains("heat") || score.explanation.lowercased().contains("hot"))
    }
}
