import SwiftUI

/// Detailed inspection view for a selected forecast day displaying comprehensive weather measurements and explanation.
public struct DayDetailView: View {
    public let rankedDay: RankedDay
    public let activity: ActivityType

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    public init(rankedDay: RankedDay, activity: ActivityType) {
        self.rankedDay = rankedDay
        self.activity = activity
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Date and Rank
                headerSection

                // Score Card Banner
                scoreBanner

                // Explanation Section
                explanationSection

                // Meteorological Metrics Grid
                metricsGridSection

                // Cross-Activity Comparison
                crossActivitySection
            }
            .padding(16)
        }
        .background(Color.appGroupedBackground)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("#\(rankedDay.rank) Best Day")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(rankedDay.rank == 1 ? Color.yellow.opacity(0.3) : Color.secondary.opacity(0.15), in: Capsule())

                Spacer()

                Label(activity.displayName, systemImage: activity.symbolName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.accentColor)
            }

            Text(Self.dateFormatter.string(from: rankedDay.assessment.date))
                .font(.title2.bold())
                .foregroundStyle(.primary)
        }
    }

    private var scoreBanner: some View {
        SuitabilityBadgeView(score: rankedDay.score, style: .prominentBanner)
    }

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis & Conditions")
                .font(.headline)

            Text(rankedDay.score.explanation)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.appSecondaryGroupedBackground))
    }

    private var metricsGridSection: some View {
        let metrics = rankedDay.assessment.metrics
        return VStack(alignment: .leading, spacing: 12) {
            Text("Weather Measurements")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricTile(
                    title: "Temperature",
                    value: "\(Int(round(metrics.temperatureMin)))° to \(Int(round(metrics.temperatureMax)))°C",
                    icon: "thermometer.medium"
                )
                metricTile(
                    title: "Precipitation",
                    value: "\(String(format: "%.1f", metrics.precipitationSum)) mm (\(metrics.precipitationProbabilityMax)%)",
                    icon: "cloud.rain"
                )
                metricTile(
                    title: "Snowfall",
                    value: "\(String(format: "%.1f", metrics.snowfallSum)) cm",
                    icon: "snowflake"
                )
                metricTile(
                    title: "Max Wind Speed",
                    value: "\(Int(round(metrics.windSpeedMax))) km/h",
                    icon: "wind"
                )
                if let wave = metrics.waveHeightMax {
                    metricTile(
                        title: "Wave Height",
                        value: "\(String(format: "%.1f", wave)) m",
                        icon: "water.waves"
                    )
                } else {
                    metricTile(
                        title: "Wave Height",
                        value: "Unavailable (Inland)",
                        icon: "water.waves"
                    )
                }
                if let period = metrics.wavePeriodMax {
                    metricTile(
                        title: "Wave Period",
                        value: "\(Int(round(period))) s",
                        icon: "timer"
                    )
                } else {
                    metricTile(
                        title: "Wave Period",
                        value: "Unavailable (Inland)",
                        icon: "timer"
                    )
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.appSecondaryGroupedBackground))
    }

    private var crossActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Other Activities for This Day")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(ActivityType.allCases.filter { $0 != activity }) { otherActivity in
                    let score = rankedDay.assessment.score(for: otherActivity)
                    HStack {
                        Label(otherActivity.displayName, systemImage: otherActivity.symbolName)
                            .font(.subheadline)
                        Spacer()
                        if let v = score.value {
                            Text("\(v)/100")
                                .font(.subheadline.bold())
                                .foregroundStyle(colorForScore(v))
                        } else {
                            Text("N/A")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.appSecondaryGroupedBackground))
    }

    private func metricTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.appTertiaryGroupedBackground))
    }

    private func colorForScore(_ value: Int) -> Color {
        if value >= 70 { return .green }
        if value >= 40 { return .orange }
        return .red
    }
}
