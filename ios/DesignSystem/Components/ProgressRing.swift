import SwiftUI

public struct LuminaProgressRing: View {
    var progress: Double // 0.0 to 1.0
    var lineWidth: CGFloat
    var gradient: LinearGradient
    var showLabel: Bool
    
    public init(
        progress: Double,
        lineWidth: CGFloat = 10,
        gradient: LinearGradient = LuminaTheme.primaryGradient,
        showLabel: Bool = true
    ) {
        self.progress = min(max(progress, 0.0), 1.0)
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.showLabel = showLabel
    }
    
    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            
            // Progress arc
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
            
            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(LuminaFont.subheadline().weight(.bold))
                    .foregroundColor(.primary)
            }
        }
    }
}
