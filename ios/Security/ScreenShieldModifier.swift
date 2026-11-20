import SwiftUI

// MARK: - OWASP Privacy Shield: Blurs App Snapshot in App Switcher
public struct ScreenShieldModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    
    public func body(content: Content) -> some View {
        ZStack {
            content
            
            if scenePhase != .active {
                ZStack {
                    Color(uiColor: .systemBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(LuminaTheme.primaryGradient)
                        Text("Lumina Terlindungi")
                            .font(LuminaFont.headline())
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

public extension View {
    func enableSecurityShield() -> some View {
        modifier(ScreenShieldModifier())
    }
}
