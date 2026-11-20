import SwiftUI

public struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Avatar & Profile
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LuminaTheme.primaryGradient.opacity(0.18))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(LuminaTheme.primaryGradient)
                    }
                    
                    Text("Selamat Datang, \(viewModel.profileName)")
                        .font(LuminaFont.title2())
                    
                    Text("Masukkan 6 Digit PIN Master Anda")
                        .font(LuminaFont.caption())
                        .foregroundColor(.secondary)
                }
                
                // 6 Pin Dots Indicator
                HStack(spacing: 16) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(index < viewModel.enteredPasscode.count ? Color(hex: "6366F1") : Color.primary.opacity(0.15))
                            .frame(width: 14, height: 14)
                            .scaleEffect(index < viewModel.enteredPasscode.count ? 1.15 : 1.0)
                            .animation(.spring(response: 0.2), value: viewModel.enteredPasscode.count)
                    }
                }
                .padding(.vertical, 8)
                
                // Error / Lockout Warning
                if viewModel.lockoutSeconds > 0 {
                    Text("Terkunci: Coba lagi dalam \(viewModel.lockoutSeconds) detik")
                        .font(LuminaFont.caption().weight(.bold))
                        .foregroundColor(.red)
                } else if let err = viewModel.errorMessage {
                    Text(err)
                        .font(LuminaFont.caption())
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // Number Pad (1 - 9, Biometrics, 0, Delete)
                VStack(spacing: 14) {
                    HStack(spacing: 28) {
                        keypadButton("1")
                        keypadButton("2")
                        keypadButton("3")
                    }
                    HStack(spacing: 28) {
                        keypadButton("4")
                        keypadButton("5")
                        keypadButton("6")
                    }
                    HStack(spacing: 28) {
                        keypadButton("7")
                        keypadButton("8")
                        keypadButton("9")
                    }
                    HStack(spacing: 28) {
                        // Biometrics shortcut button
                        Button(action: {
                            Task { await viewModel.unlockWithBiometric() }
                        }) {
                            Image(systemName: "faceid")
                                .font(.system(size: 26))
                                .foregroundColor(Color(hex: "6366F1"))
                                .frame(width: 72, height: 72)
                        }
                        
                        keypadButton("0")
                        
                        // Delete Button
                        Button(action: {
                            viewModel.deleteDigit()
                        }) {
                            Image(systemName: "delete.left.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.secondary)
                                .frame(width: 72, height: 72)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            Task {
                await viewModel.unlockWithBiometric()
            }
        }
    }
    
    private func keypadButton(_ digit: String) -> some View {
        Button(action: {
            viewModel.appendDigit(digit)
        }) {
            Text(digit)
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                )
        }
    }
}
