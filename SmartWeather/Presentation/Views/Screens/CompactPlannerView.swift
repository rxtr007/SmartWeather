import SwiftUI

/// Single-pane layout optimized for compact screens, conventional iPhones, and the iPhone Duo outer display.
public struct CompactPlannerView: View {
    @Bindable public var viewModel: WeatherPlannerViewModel
    @State private var sheetDetailDay: RankedDay?

    public init(viewModel: WeatherPlannerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Search Bar
                LocationSearchBar(
                    text: Binding(
                        get: { viewModel.searchQuery },
                        set: { viewModel.searchQueryDidChange(to: $0) }
                    ),
                    isSearching: viewModel.isSearching,
                    suggestions: viewModel.searchResults,
                    onSelect: { location in
                        viewModel.selectLocation(location)
                    }
                )
                .padding(.top, 8)

                // Activity Selection Bar
                ActivityPickerBar(selectedActivity: viewModel.selectedActivity) { activity in
                    viewModel.selectActivity(activity)
                }

                // Main Content Area
                contentArea
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("SmartWeather")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $sheetDetailDay) { day in
                NavigationStack {
                    DayDetailView(rankedDay: day, activity: viewModel.selectedActivity)
                        .navigationTitle("Day Details")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    sheetDetailDay = nil
                                }
                            }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoadingForecast {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Analyzing 7-day weather conditions...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        } else if let error = viewModel.errorMessage {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text("Unable to Load Weather")
                    .font(.headline)
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
        } else if viewModel.rankedDays.isEmpty {
            emptyState
        } else {
            forecastList
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        Spacer()
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 54))
                .foregroundStyle(.secondary)
            Text("Search a Destination")
                .font(.headline)
            Text("Enter a city above to rank 7-day suitability for skiing, surfing, or sightseeing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        Spacer()
    }

    private var forecastList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let location = viewModel.selectedLocation {
                    HStack {
                        Label(location.displayName, systemImage: "location.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }

                ForEach(viewModel.rankedDays) { day in
                    Button {
                        sheetDetailDay = day
                    } label: {
                        RankedDayCard(
                            rankedDay: day,
                            activity: viewModel.selectedActivity,
                            isSelected: false
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
    }
}
