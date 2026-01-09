import SwiftUI

struct NeonLoadingBar: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 4)

                // Animated bar
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, NeonTheme.primary, NeonTheme.secondary, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * 0.3, height: 4)
                    .neonGlow(color: NeonTheme.primary, radius: 5)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.3)
            }
            .clipped()
        }
        .frame(height: 4)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
