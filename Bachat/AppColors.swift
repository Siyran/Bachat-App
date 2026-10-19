import SwiftUI

/// Semantic color tokens adapting dynamically to light and dark user interface styles.
extension Color {
    /// Adaptive primary background color.
    static let appBackground = Color(UIColor.systemBackground)
    /// Adaptive primary foreground and label text color.
    static let appForeground = Color(UIColor.label)
}
