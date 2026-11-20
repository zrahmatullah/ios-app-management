import SwiftUI

public struct LuminaAmountText: View {
    let amount: Int64
    var type: String? // "INCOME", "EXPENSE", nil
    var font: Font
    var currencySymbol: String
    
    public init(
        amount: Int64,
        type: String? = nil,
        font: Font = LuminaFont.title2(),
        currencySymbol: String = "Rp"
    ) {
        self.amount = amount
        self.type = type
        self.font = font
        self.currencySymbol = currencySymbol
    }
    
    public var body: some View {
        Text(formattedString)
            .font(font)
            .foregroundColor(textColor)
    }
    
    private var formattedString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: abs(amount))) ?? "\(abs(amount))"
        
        var prefix = ""
        if let type = type {
            if type == "INCOME" {
                prefix = "+ "
            } else if type == "EXPENSE" {
                prefix = "- "
            }
        }
        
        return "\(prefix)\(currencySymbol) \(formattedNumber)"
    }
    
    private var textColor: Color {
        guard let type = type else { return .primary }
        switch type {
        case "INCOME":
            return Color(hex: "10B981")
        case "EXPENSE":
            return Color(hex: "F43F5E")
        default:
            return .primary
        }
    }
}
