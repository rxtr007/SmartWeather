import SwiftUI

/// Semantic badge displaying suitability tier (Suitable, Marginal, Unsuitable, Unavailable)
/// with unified typography, color tokens, and VoiceOver accessibility labels.
public struct SuitabilityBadgeView: View {
    public enum Style {
        case compactPill
        case prominentBanner
    }

    public let score: SuitabilityScore
    public let style: Style

    public init(score: SuitabilityScore, style: Style = .compactPill) {
        self.score = score
        self.style = style
    }

    public var body: some View {
        switch style {
        case .compactPill:
            HStack(spacing: 5) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(statusTitle)
                    .font(.caption2.weight(.semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.16), in: Capsule())
            .foregroundStyle(statusColor)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Suitability: \(statusTitle)")

        case .prominentBanner:
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suitability Assessment")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(statusTitle)
                        .font(.title2.bold())
                        .foregroundStyle(statusColor)
                }

                Spacer()

                if let value = score.value {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(value)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                        Text("/100")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(statusColor)
                } else {
                    Text("N/A")
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appSecondaryGroupedBackground)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityBannerLabel)
        }
    }

    private var statusTitle: String {
        switch score.status {
        case .suitable: return "Suitable"
        case .marginal: return "Marginal"
        case .unsuitable: return "Unsuitable"
        case .unavailable: return "Unavailable"
        }
    }

    private var statusColor: Color {
        Color.suitabilityColor(for: score.status)
    }

    private var accessibilityBannerLabel: String {
        if let value = score.value {
            return "Suitability Assessment: \(statusTitle), score \(value) out of 100"
        } else {
            return "Suitability Assessment: \(statusTitle)"
        }
    }
}
