import Foundation

/// Wire response from Open-Meteo Geocoding API (`https://geocoding-api.open-meteo.com/v1/search`)
public struct GeocodingResponse: Codable, Sendable {
    public let results: [GeocodingLocation]?

    public init(results: [GeocodingLocation]? = nil) {
        self.results = results
    }
}

/// Individual location record returned by Open-Meteo Geocoding API.
public struct GeocodingLocation: Codable, Sendable, Identifiable, Equatable {
    public let id: Int
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let countryCode: String?
    public let country: String?
    public let admin1: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case countryCode = "country_code"
        case country
        case admin1
    }

    public init(
        id: Int,
        name: String,
        latitude: Double,
        longitude: Double,
        countryCode: String? = nil,
        country: String? = nil,
        admin1: String? = nil
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.countryCode = countryCode
        self.country = country
        self.admin1 = admin1
    }

    /// Clean human-readable display title (e.g., "Denver, Colorado, United States" or "Tokyo, Japan")
    public var displayName: String {
        let components = [name, admin1, country].compactMap { $0 }.filter { !$0.isEmpty }
        return components.joined(separator: ", ")
    }

    /// Subtitle for secondary display in search lists (e.g., "Colorado, United States")
    public var formattedSubtitle: String {
        let components = [admin1, country].compactMap { $0 }.filter { !$0.isEmpty }
        return components.joined(separator: ", ")
    }
}
