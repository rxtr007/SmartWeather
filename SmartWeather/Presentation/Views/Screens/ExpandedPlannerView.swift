import SwiftUI

/// Expanded dual-pane layout designed for the iPhone Duo inner display and expanded widths.
/// Uses NavigationSplitView to place forecast rankings and detailed inspection side by side,
/// allowing system containers to naturally avoid the center division / fold.
public struct ExpandedPlannerView: View {
    @Bindable public var viewModel: WeatherPlannerViewModel

    public init(viewModel: WeatherPlannerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationSplitView {
            // Sidebar: Search, Activity Filter, and 7-Day Ranked List
            VStack(spacing: 12) {
                LocationSearchBar(
                    text: Binding(
                        get: { viewModel.searchQuery },
                        set: { viewModel.searchQueryDidChange(to: $0) }
                    ),
                    isSearching: viewModel.isSearching,
                    suggestions: viewModel.searchResults,
                    onSelect: { location in
                        Task {
                            await viewModel.selectLocation(location)
                        }
                    }
                )
                .padding(.top, 8)

                ActivityPickerBar(selectedActivity: viewModel.selectedActivity) { activity in
                    viewModel.selectActivity(activity)
                }

                sidebarContent
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("SmartWeather")
        } detail: {
            // Detail Pane: Full Day Inspection
            detailContent
        }
    }

    @ViewBuilder
    private var sidebarContent: some View {
        if viewModel.isLoadingForecast {
            Spacer()
            ProgressView("Analyzing 7-day weather...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        } else if let error = viewModel.errorMessage {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            Spacer()
        } else if viewModel.rankedDays.isEmpty {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("Search for a city to begin")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    if let location = viewModel.selectedLocation {
                        HStack {
                            Label(location.displayName, systemImage: "location.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }

                    ForEach(viewModel.rankedDays) { day in
                        Button {
                            viewModel.selectDay(day)
                        } label: {
                            RankedDayCard(
                                rankedDay: day,
                                activity: viewModel.selectedActivity,
                                isSelected: viewModel.selectedDay?.id == day.id
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        if let selectedDay = viewModel.selectedDay {
            DayDetailView(rankedDay: selectedDay, activity: viewModel.selectedActivity)
        } else if viewModel.isLoadingForecast {
            ProgressView()
                .controlSize(.large)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Select a Day to View Analysis")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appGroupedBackground)
        }
    }
}
