import SwiftUI

public struct SafeToSpendCard: View {
    let dailySafeAmount: Int64
    let daysRemaining: Int
    let status: String // SAFE, WARNING, OVERSPENT
    
    public init(dailySafeAmount: Int64, daysRemaining: Int, status: String) {
        self.dailySafeAmount = dailySafeAmount
        self.daysRemaining = daysRemaining
        self.status = status
    }
    
    public var body: some View {
        LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.18))
                            .frame(width: 32, height: 32)
                        Image(systemName: statusIcon)
                            .foregroundColor(statusColor)
                            .font(.system(size: 14, weight: .bold))
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Uang Aman Belanja Hari Ini")
                            .font(LuminaFont.caption())
                            .foregroundColor(.secondary)
                        Text(statusMessage)
                            .font(LuminaFont.caption().weight(.bold))
                            .foregroundColor(statusColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Sisa Bulan")
                            .font(LuminaFont.caption())
                            .foregroundColor(.secondary)
                        Text("\(daysRemaining) hari")
                            .font(LuminaFont.caption().weight(.semibold))
                    }
                }
                
                Divider()
                
                HStack(alignment: .firstTextBaseline) {
                    LuminaAmountText(
                        amount: dailySafeAmount,
                        font: .system(size: 24, weight: .bold, design: .rounded)
                    )
                    Text("/ hari")
                        .font(LuminaFont.caption())
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Safe-to-Spend™")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "6366F1"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(hex: "6366F1").opacity(0.12))
                        )
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case "SAFE": return Color(hex: "10B981")
        case "WARNING": return Color(hex: "F59E0B")
        default: return Color(hex: "F43F5E")
        }
    }
    
    private var statusIcon: String {
        switch status {
        case "SAFE": return "checkmark.shield.fill"
        case "WARNING": return "exclamationmark.shield.fill"
        default: return "xmark.shield.fill"
        }
    }
    
    private var statusMessage: String {
        switch status {
        case "SAFE": return "Kondisi Aman"
        case "WARNING": return "Mendekati Batas"
        default: return "Defisit / Hati-hati"
        }
    }
}
