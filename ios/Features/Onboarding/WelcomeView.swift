import SwiftUI

public struct WelcomeView: View {
    let onGetStarted: () -> Void
    @State private var appearAnimation: Bool = false
    @State private var activeSlide: Int = 0
    
    public init(onGetStarted: @escaping () -> Void) {
        self.onGetStarted = onGetStarted
    }
    
    public var body: some View {
        ZStack {
            // Elegant background ambient glows
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            Circle()
                .fill(Color(hex: "6366F1").opacity(0.2))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -80, y: -200)
            
            Circle()
                .fill(Color(hex: "EC4899").opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: 100, y: 180)
            
            VStack(spacing: 28) {
                Spacer()
                
                // Animated App Icon Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(LuminaTheme.glassBorder, lineWidth: 1.5)
                        )
                        .shadow(color: Color(hex: "6366F1").opacity(0.35), radius: 24, y: 10)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(LuminaTheme.primaryGradient)
                }
                .scaleEffect(appearAnimation ? 1.0 : 0.8)
                .opacity(appearAnimation ? 1.0 : 0.0)
                
                // Titles
                VStack(spacing: 10) {
                    Text("Selamat Datang di")
                        .font(LuminaFont.subheadline())
                        .foregroundColor(.secondary)
                    
                    Text("Lumina")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(LuminaTheme.primaryGradient)
                    
                    Text("Satu aplikasi all-in-one untuk mengelola keuangan, target impian, agenda, dan catatan harian Anda.")
                        .font(LuminaFont.subheadline())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .offset(y: appearAnimation ? 0 : 20)
                .opacity(appearAnimation ? 1.0 : 0.0)
                
                // Feature Highlights
                VStack(spacing: 14) {
                    featureRow(
                        icon: "wallet.pass.fill",
                        color: "6366F1",
                        title: "Multi-Dompet & Anggaran",
                        description: "Catat pengeluaran, transfer antar rekening, dan pantau budget bulanan."
                    )
                    
                    featureRow(
                        icon: "gift.fill",
                        color: "F59E0B",
                        title: "Celengan & Target Hidup",
                        description: "Saran setoran cerdas dan checklist milestone menuju impian Anda."
                    )
                    
                    featureRow(
                        icon: "lock.shield.fill",
                        color: "10B981",
                        title: "100% Offline & Privat",
                        description: "Data tersimpan lokal di iPhone. Tanpa akun, tanpa iklan, aman terlindungi."
                    )
                }
                .padding(.horizontal, 20)
                .offset(y: appearAnimation ? 0 : 30)
                .opacity(appearAnimation ? 1.0 : 0.0)
                
                Spacer()
                
                // Primary Action Button
                LuminaButton("Mulai Kelola Hidup", icon: "arrow.right", gradient: LuminaTheme.primaryGradient) {
                    HapticManager.impact(.medium)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        onGetStarted()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .offset(y: appearAnimation ? 0 : 40)
                .opacity(appearAnimation ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                appearAnimation = true
            }
        }
    }
    
    private func featureRow(icon: String, color: String, title: String, description: String) -> some View {
        LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: color).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: color))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(LuminaFont.subheadline().weight(.bold))
                        .foregroundColor(.primary)
                    Text(description)
                        .font(LuminaFont.caption())
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }
        }
    }
}
