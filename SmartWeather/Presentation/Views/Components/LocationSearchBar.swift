import SwiftUI

/// Location search input bar with debounced suggestions dropdown and quick-clear controls.
public struct LocationSearchBar: View {
    @Binding public var text: String
    public let isSearching: Bool
    public let suggestions: [GeocodingLocation]
    public let onSelect: (GeocodingLocation) -> Void

    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        isSearching: Bool,
        suggestions: [GeocodingLocation],
        onSelect: @escaping (GeocodingLocation) -> Void
    ) {
        self._text = text
        self.isSearching = isSearching
        self.suggestions = suggestions
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Row
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search city (e.g., Tokyo, Innsbruck, Honolulu)...", text: $text)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .focused($isFocused)

                if isSearching {
                    ProgressView()
                        .controlSize(.small)
                } else if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.appSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Suggestions Dropdown
            if !suggestions.isEmpty && isFocused {
                VStack(spacing: 0) {
                    ForEach(suggestions) { location in
                        Button {
                            isFocused = false
                            onSelect(location)
                        } label: {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(Color.accentColor)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(location.name)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)

                                    if !location.formattedSubtitle.isEmpty {
                                        Text(location.formattedSubtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        if location.id != suggestions.last?.id {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
                .background(Color.appSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
    }
}
