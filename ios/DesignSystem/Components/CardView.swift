import SwiftUI

public struct LuminaCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat
    var padding: CGFloat
    
    public init(
        cornerRadius: CGFloat = LuminaTheme.cornerRadiusLarge,
        padding: CGFloat = 18,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(LuminaTheme.glassBorder, lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}
