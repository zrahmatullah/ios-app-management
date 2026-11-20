import SwiftUI

public struct LuminaEmptyStateView: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let actionTitle: LocalizedStringKey?
    let action: (() -> Void)?
    
    public init(
        icon: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LuminaTheme.primaryGradient.opacity(0.12))
                    .frame(width: 88, height: 88)
                
                Image(systemName: icon)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(LuminaTheme.primaryGradient)
            }
            .padding(.bottom, 4)
            
            Text(title)
                .font(LuminaFont.headline())
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(LuminaFont.subheadline())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.impact(.light)
                    action()
                }) {
                    Text(actionTitle)
                        .font(LuminaFont.subheadline().weight(.semibold))
                        .foregroundStyle(LuminaTheme.primaryGradient)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.primary.opacity(0.06))
                        )
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
