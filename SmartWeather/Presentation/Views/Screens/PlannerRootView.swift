import SwiftUI

/// Root adaptive view switching between Compact (outer display / single pane)
/// and Expanded (inner display / NavigationSplitView) configurations while preserving complete state continuity.
public struct PlannerRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State public var viewModel: WeatherPlannerViewModel

    public init(viewModel: WeatherPlannerViewModel = WeatherPlannerViewModel()) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                ExpandedPlannerView(viewModel: viewModel)
            } else {
                CompactPlannerView(viewModel: viewModel)
            }
        }
        .task {
            // Optional: If no location is selected initially, load a default popular hub (e.g. Innsbruck or Honolulu)
            // or leave empty for user search. Let's pre-load Innsbruck so the app opens with rich data ready to test!
            if viewModel.selectedLocation == nil {
                let defaultLocation = GeocodingLocation(
                    id: 2775220,
                    name: "Innsbruck",
                    latitude: 47.2692,
                    longitude: 11.4041,
                    countryCode: "AT",
                    country: "Austria",
                    admin1: "Tyrol"
                )
                await viewModel.selectLocation(defaultLocation).value
            }
        }
    }
}
