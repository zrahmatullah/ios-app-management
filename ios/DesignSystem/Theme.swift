import SwiftUI

// MARK: - Color Tokens & Gradients
public enum LuminaTheme {
    // Primary Gradient Accents
    public static let primaryGradient = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6"), Color(hex: "EC4899")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let incomeGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let expenseGradient = LinearGradient(
        colors: [Color(hex: "F43F5E"), Color(hex: "E11D48")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let savingsGradient = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let cardBackground = Color("CardBackground", bundle: nil)
    public static let background = Color("BackgroundColor", bundle: nil)
    public static let glassBorder = Color.white.opacity(0.18)
    
    public static let cornerRadiusLarge: CGFloat = 24
    public static let cornerRadiusMedium: CGFloat = 16
    public static let cornerRadiusSmall: CGFloat = 10
}

// MARK: - Hex Color Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Haptic Feedback Helper
public enum HapticManager {
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
