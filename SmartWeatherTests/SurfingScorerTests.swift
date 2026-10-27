import Foundation
import Testing

@Suite("Surfing Scorer Tests")
struct SurfingScorerTests {
    @Test("Ideal clean groundswell scores in suitable tier")
    func idealGroundswell() throws {
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
        let value = try #require(score.value)
        
        #expect(value >= 80)
        #expect(score.status == .suitable)
        #expect(score.explanation.lowercased().contains("swell") || score.explanation.lowercased().contains("wave"))
    }
    
    @Test("Flat summer conditions score unsuitable")
    func flatSummerConditions() throws {
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
        let value = try #require(score.value)
        
        #expect(value <= 20)
        #expect(score.status == .unsuitable)
        #expect(score.explanation.lowercased().contains("flat") || score.explanation.lowercased().contains("small"))
    }
    
    @Test("Blown out choppy windswell scores unsuitable")
    func blownOutWindswell() throws {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 15.0,
            temperatureMax: 19.0,
            precipitationSum: 4.0,
            precipitationProbabilityMax: 60,
            snowfallSum: 0.0,
            windSpeedMax: 42.0,
            waveHeightMax: 2.2,
            wavePeriodMax: 7.0
        )
        
        let score = SurfingScorer.score(metrics: metrics)
        let value = try #require(score.value)
        
        #expect(value < 40)
        #expect(score.status == .unsuitable)
        #expect(score.explanation.lowercased().contains("wind") || score.explanation.lowercased().contains("chop"))
    }
    
    @Test("Inland coordinates missing marine wave data return unavailable status")
    func inlandMissingMarineData() {
        let metrics = DailyWeatherMetrics(
            date: Date(),
            temperatureMin: 12.0,
            temperatureMax: 22.0,
            precipitationSum: 0.0,
            precipitationProbabilityMax: 0,
            snowfallSum: 0.0,
            windSpeedMax: 10.0,
            waveHeightMax: nil,
            wavePeriodMax: nil
        )
        
        let score = SurfingScorer.score(metrics: metrics)
        #expect(score.value == nil)
        #expect(score.status == .unavailable(reason: "Marine wave data is unavailable for inland locations"))
        #expect(score.explanation.contains("unavailable"))
    }
}
