import SwiftUI

/// Horizontal activity selection bar displaying SF symbols and names for the 4 target activities.
public struct ActivityPickerBar: View {
    public let selectedActivity: ActivityType
    public let onSelect: (ActivityType) -> Void

    public init(
        selectedActivity: ActivityType,
        onSelect: @escaping (ActivityType) -> Void
    ) {
        self.selectedActivity = selectedActivity
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ActivityType.allCases) { activity in
                    let isSelected = activity == selectedActivity
                    Button {
                        onSelect(activity)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: activity.symbolName)
                                .font(.subheadline)
                            Text(activity.displayName)
                                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            isSelected ? Color.accentColor : Color.secondary.opacity(0.12),
                            in: Capsule()
                        )
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(activity.displayName)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
}
