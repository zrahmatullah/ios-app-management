import SwiftUI

public struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var shakeOffset: CGFloat = 0
    
    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Avatar & Profile
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LuminaTheme.primaryGradient.opacity(0.18))
                            .frame(width: 86, height: 86)
                        
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(LuminaTheme.primaryGradient)
                    }
                    
                    Text("Selamat Datang, \(viewModel.profileName)")
                        .font(LuminaFont.title2().weight(.bold))
                    
                    Text("Masukkan 6 Digit PIN Master Anda")
                        .font(LuminaFont.caption())
                        .foregroundColor(.secondary)
                }
                
                // 6 Pin Dots Indicator with Shake Animation
                HStack(spacing: 16) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(index < viewModel.enteredPasscode.count ? Color(hex: "6366F1") : Color.primary.opacity(0.15))
                            .frame(width: 16, height: 16)
                            .scaleEffect(index < viewModel.enteredPasscode.count ? 1.2 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: viewModel.enteredPasscode.count)
                    }
                }
                .offset(x: shakeOffset)
                .padding(.vertical, 8)
                
                // Error / Lockout Display
                if viewModel.lockoutSeconds > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .foregroundColor(.red)
                        Text("Brankas Terkunci: \(viewModel.lockoutSeconds) detik")
                            .font(LuminaFont.caption().weight(.bold))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                } else if let err = viewModel.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(err)
                            .font(LuminaFont.caption())
                            .foregroundColor(.red)
                    }
                    .transition(.opacity)
                }
                
                Spacer()
                
                // Number Pad (1 - 9, Biometrics, 0, Delete)
                VStack(spacing: 12) {
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
                        // Face ID button
                        Button(action: {
                            Task { await viewModel.unlockWithBiometric() }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "faceid")
                                    .font(.system(size: 26))
                                    .foregroundColor(Color(hex: "6366F1"))
                                Text("Face ID")
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 72, height: 72)
                        }
                        .disabled(viewModel.lockoutSeconds > 0)
                        
                        keypadButton("0")
                        
                        // Delete Button
                        Button(action: {
                            viewModel.deleteDigit()
                        }) {
                            Image(systemName: "delete.left.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                                .frame(width: 72, height: 72)
                        }
                        .disabled(viewModel.lockoutSeconds > 0)
                    }
                }
                .padding(.bottom, 16)
                
                // OWASP & Privacy Footer
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 11))
                    Text("100% Offline • Terenkripsi Kriptografi Keychain")
                        .font(.system(size: 11, design: .rounded))
                }
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.bottom, 16)
            }
        }
        .onChange(of: viewModel.errorMessage) { err in
            if err != nil {
                triggerShake()
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
                .background(Color.primary.opacity(0.04))
                .clipShape(Circle())
        }
        .disabled(viewModel.lockoutSeconds > 0)
    }
    
    private func triggerShake() {
        withAnimation(.default) {
            shakeOffset = -12
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) {
                shakeOffset = 12
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default) {
                shakeOffset = -8
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.default) {
                shakeOffset = 0
            }
        }
    }
}
