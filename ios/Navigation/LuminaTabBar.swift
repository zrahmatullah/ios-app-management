import SwiftUI

public struct LuminaTabBar: View {
    @Binding var selectedTab: Int
    let onQuickAddTapped: () -> Void
    
    public init(selectedTab: Binding<Int>, onQuickAddTapped: @escaping () -> Void) {
        self._selectedTab = selectedTab
        self.onQuickAddTapped = onQuickAddTapped
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, title: "Beranda", icon: "house.fill")
            tabButton(index: 1, title: "Keuangan", icon: "creditcard.fill")
            
            // Center Floating Action Button
            Button(action: {
                HapticManager.impact(.medium)
                onQuickAddTapped()
            }) {
                ZStack {
                    Circle()
                        .fill(LuminaTheme.primaryGradient)
                        .frame(width: 54, height: 54)
                        .shadow(color: Color(hex: "6366F1").opacity(0.4), radius: 10, y: 5)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -14)
            .padding(.horizontal, 10)
            
            tabButton(index: 2, title: "Target", icon: "target")
            tabButton(index: 3, title: "Kalender", icon: "calendar")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 22)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(LuminaTheme.glassBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: 10)
        )
        .padding(.horizontal, 16)
    }
    
    private func tabButton(index: Int, title: String, icon: String) -> some View {
        Button(action: {
            HapticManager.impact(.light)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == index ? Color(hex: "6366F1") : .secondary)
                
                Text(title)
                    .font(LuminaFont.caption())
                    .foregroundColor(selectedTab == index ? Color(hex: "6366F1") : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
