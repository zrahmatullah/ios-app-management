import SwiftUI

public struct LuminaCategoryChip: View {
    let name: String
    let icon: String
    let colorHex: String
    var isSelected: Bool
    let action: (() -> Void)?
    
    public init(
        name: String,
        icon: String,
        colorHex: String,
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            HapticManager.impact(.light)
            action?()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color(hex: colorHex))
                
                Text(name)
                    .font(LuminaFont.subheadline())
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: colorHex) : Color(hex: colorHex).opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color(hex: colorHex).opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
