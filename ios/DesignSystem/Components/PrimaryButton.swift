import SwiftUI

public struct LuminaButton: View {
    let title: LocalizedStringKey
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void
    
    public init(
        _ title: LocalizedStringKey,
        icon: String? = nil,
        gradient: LinearGradient = LuminaTheme.primaryGradient,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            HapticManager.impact(.light)
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(LuminaFont.headline())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: LuminaTheme.cornerRadiusMedium, style: .continuous)
                    .fill(gradient)
                    .shadow(color: Color(hex: "6366F1").opacity(0.35), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

public struct ScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
