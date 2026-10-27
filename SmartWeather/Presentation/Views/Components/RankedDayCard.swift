import SwiftUI

/// Card view representing a single ranked forecast day with activity score, status badge, and key metrics.
public struct RankedDayCard: View {
    public let rankedDay: RankedDay
    public let activity: ActivityType
    public let isSelected: Bool

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    public init(
        rankedDay: RankedDay,
        activity: ActivityType,
        isSelected: Bool = false
    ) {
        self.rankedDay = rankedDay
        self.activity = activity
        self.isSelected = isSelected
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                // Rank Badge
                Text("#\(rankedDay.rank)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(rankedDay.rank == 1 ? Color.yellow.opacity(0.3) : Color.secondary.opacity(0.15), in: Capsule())
                    .foregroundStyle(rankedDay.rank == 1 ? Color.primary : Color.secondary)

                // Formatted Date
                Text(Self.dayFormatter.string(from: rankedDay.assessment.date))
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                // Score Badge
                scoreBadge
            }

            // Status & Explanation Preview
            HStack(spacing: 8) {
                statusPill
                Text(rankedDay.score.explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Key Meteorological Metrics Row
            metricsRow
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var scoreBadge: some View {
        if let value = rankedDay.score.value {
            HStack(spacing: 2) {
                Text("\(value)")
                    .font(.title3.bold())
                Text("/100")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(statusColor)
        } else {
            Text("N/A")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
        }
    }

    private var statusPill: some View {
        Text(statusTitle)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.18), in: Capsule())
            .foregroundStyle(statusColor)
    }

    private var statusTitle: String {
        switch rankedDay.score.status {
        case .suitable: return "Suitable"
        case .marginal: return "Marginal"
        case .unsuitable: return "Unsuitable"
        case .unavailable: return "Unavailable"
        }
    }

    private var statusColor: Color {
        switch rankedDay.score.status {
        case .suitable: return .green
        case .marginal: return .orange
        case .unsuitable: return .red
        case .unavailable: return .secondary
        }
    }

    private var metricsRow: some View {
        let metrics = rankedDay.assessment.metrics
        return HStack(spacing: 12) {
            Label("\(Int(round(metrics.temperatureMin)))° / \(Int(round(metrics.temperatureMax)))°C", systemImage: "thermometer.medium")
            Label("\(metrics.precipitationProbabilityMax)%", systemImage: "cloud.rain")
            Label("\(Int(round(metrics.windSpeedMax))) km/h", systemImage: "wind")

            if activity == .skiing && metrics.snowfallSum > 0 {
                Label("\(Int(round(metrics.snowfallSum))) cm", systemImage: "snowflake")
            } else if activity == .surfing, let wave = metrics.waveHeightMax {
                Label(String(format: "%.1f m", wave), systemImage: "water.waves")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
