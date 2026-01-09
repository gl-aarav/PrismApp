import SwiftUI

struct NeonTheme {
    static let primary = Color(red: 0.0, green: 0.8, blue: 0.4)  // Green
    static let secondary = Color(red: 0.0, green: 0.4, blue: 0.9)  // Blue
    static let tertiary = Color(red: 0.0, green: 0.9, blue: 0.6)  // Mint
    static let background = Color(red: 0.05, green: 0.05, blue: 0.08)

    static let gradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .leading,
        endPoint: .trailing
    )
}

struct NeonGlow: ViewModifier {
    var color: Color
    var radius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: radius * 2, x: 0, y: 0)
    }
}

extension View {
    func neonGlow(color: Color = NeonTheme.primary, radius: CGFloat = 10) -> some View {
        self.modifier(NeonGlow(color: color, radius: radius))
    }
}
