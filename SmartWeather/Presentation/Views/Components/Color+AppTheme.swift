import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension Color {
    public static var appGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color.secondary.opacity(0.08)
        #endif
    }

    public static var appSecondaryGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color.secondary.opacity(0.14)
        #endif
    }

    public static var appTertiaryGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .tertiarySystemGroupedBackground)
        #else
        Color.secondary.opacity(0.2)
        #endif
    }
}
