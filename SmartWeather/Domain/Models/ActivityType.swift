import Foundation

/// The activities supported by the SmartWeather planner.
public enum ActivityType: String, CaseIterable, Sendable, Identifiable, Codable {
    case skiing
    case surfing
    case outdoorSightseeing
    case indoorSightseeing
    
    public var id: String { rawValue }
    
    /// User-visible title for the activity.
    public var displayName: String {
        switch self {
        case .skiing:
            return "Skiing"
        case .surfing:
            return "Surfing"
        case .outdoorSightseeing:
            return "Outdoor Sightseeing"
        case .indoorSightseeing:
            return "Indoor Sightseeing"
        }
    }
    
    /// SF Symbol icon name representing the activity.
    public var symbolName: String {
        switch self {
        case .skiing:
            return "figure.skiing.downhill"
        case .surfing:
            return "figure.surfing"
        case .outdoorSightseeing:
            return "binoculars.fill"
        case .indoorSightseeing:
            return "building.columns.fill"
        }
    }
}
