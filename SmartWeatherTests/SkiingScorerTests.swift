import Foundation
import Testing

@Suite("Skiing Scorer Tests")
struct SkiingScorerTests {
    @Test("Ideal powder snow day scores in suitable tier with snow explanation")
    func idealPowderDay() throws {
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
        let value = try #require(score.value)
        
        #expect(value >= 80)
        #expect(score.status == .suitable)
        #expect(score.explanation.lowercased().contains("powder") || score.explanation.lowercased().contains("snow"))
    }
    
    @Test("Cold groomed day with no fresh snow scores marginal")
    func coldGroomedSnowDay() throws {
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
        let value = try #require(score.value)
        
        #expect(value >= 35 && value <= 65)
        #expect(score.status == .marginal)
    }
    
    @Test("Warm rainy day scores unsuitable due to slush and rain")
    func warmRainSlushDay() throws {
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
        let value = try #require(score.value)
        
        #expect(value < 30)
        #expect(score.status == .unsuitable)
        #expect(score.explanation.lowercased().contains("rain") || score.explanation.lowercased().contains("warm") || score.explanation.lowercased().contains("slush"))
    }
    
    @Test("High gale winds penalize score due to lift closure risks")
    func highWindLiftClosureDay() throws {
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
        let value = try #require(score.value)
        
        #expect(value < 65)
        #expect(score.explanation.lowercased().contains("wind"))
    }
}
