import SwiftUI

// MARK: - Shimmer Skeleton Loading Effect
public struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .offset(x: geo.size.width * phase)
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .mask(content)
            .onAppear {
                phase = 1.0
            }
    }
}

public extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Pulsing Logo Spinner Animation
public struct LuminaPulsingSpinner: View {
    @State private var isPulsing = false
    @State private var isRotating = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Ambient outer glow
            Circle()
                .fill(LuminaTheme.primaryGradient.opacity(0.2))
                .frame(width: 90, height: 90)
                .scaleEffect(isPulsing ? 1.25 : 0.9)
                .blur(radius: 12)
            
            // Rotating dashed gradient ring
            Circle()
                .trim(from: 0.1, to: 0.85)
                .stroke(
                    LuminaTheme.primaryGradient,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 6])
                )
                .frame(width: 68, height: 68)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
            
            // Center icon
            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(LuminaTheme.primaryGradient)
                .scaleEffect(isPulsing ? 1.1 : 0.95)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                isRotating = true
            }
        }
    }
}

// MARK: - Skeleton Card Placeholder
public struct SkeletonCardView: View {
    public init() {}
    
    public var body: some View {
        LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 140, height: 16)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.12))
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .shimmer()
                
                HStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 90, height: 14)
                        .shimmer()
                    Spacer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 70, height: 14)
                        .shimmer()
                }
            }
        }
    }
}
