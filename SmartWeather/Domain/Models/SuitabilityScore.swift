import Foundation

/// Categorical evaluation of suitability.
public enum SuitabilityStatus: Sendable, Equatable, Hashable, Codable {
    case suitable     // Score 70...100
    case marginal     // Score 40...69
    case unsuitable   // Score 0...39
    case unavailable(reason: String) // Missing critical data (e.g., inland surf)
}

/// A deterministic evaluation score (0-100) or unavailable state with explanation.
public struct SuitabilityScore: Sendable, Equatable, Hashable, Codable {
    /// Integer score between 0 and 100, or nil if data is unavailable.
    public let value: Int?
    
    /// Qualitative classification.
    public let status: SuitabilityStatus
    
    /// Clear explanation of the result based on weather factors.
    public let explanation: String
    
    /// Initializes a scored evaluation, clamping the score to 0...100 and deriving status.
    public init(value: Int, explanation: String) {
        let clamped = max(0, min(100, value))
        self.value = clamped
        self.explanation = explanation
        
        switch clamped {
        case 70...100:
            self.status = .suitable
        case 40...69:
            self.status = .marginal
        default:
            self.status = .unsuitable
        }
    }
    
    /// Private initializer for unavailable instances.
    private init(unavailableReason: String) {
        self.value = nil
        self.status = .unavailable(reason: unavailableReason)
        self.explanation = unavailableReason
    }
    
    /// Factory method for when conditions cannot be assessed (e.g. marine data for inland city).
    public static func unavailable(reason: String) -> SuitabilityScore {
        SuitabilityScore(unavailableReason: reason)
    }
}
