import Foundation
import SwiftUI

@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var enteredPasscode: String = ""
    @Published public var errorMessage: String?
    @Published public var lockoutSeconds: Int = 0
    @Published public var isUnlocked: Bool = false
    
    private var timer: Timer?
    
    public init() {}
    
    public var profileName: String {
        SecurityManager.shared.profileName
    }
    
    public func appendDigit(_ digit: String) {
        guard lockoutSeconds == 0 else { return }
        guard enteredPasscode.count < 6 else { return }
        
        enteredPasscode.append(digit)
        HapticManager.impact(.light)
        
        if enteredPasscode.count == 6 {
            verify()
        }
    }
    
    public func deleteDigit() {
        guard !enteredPasscode.isEmpty else { return }
        enteredPasscode.removeLast()
        HapticManager.impact(.light)
    }
    
    public func verify() {
        let (success, remainingLockout) = SecurityManager.shared.verifyPasscode(passcode: enteredPasscode)
        if success {
            HapticManager.notification(.success)
            withAnimation(.spring()) {
                self.isUnlocked = true
            }
        } else {
            HapticManager.notification(.error)
            enteredPasscode = ""
            if remainingLockout > 0 {
                startLockout(seconds: remainingLockout)
            } else {
                errorMessage = "PIN salah. Silakan coba lagi."
            }
        }
    }
    
    public func unlockWithBiometric() async {
        guard lockoutSeconds == 0 else { return }
        let authenticated = await BiometricAuthService.shared.authenticate(
            reason: "Buka brankas Lumina untuk mengakses data Anda"
        )
        if authenticated {
            HapticManager.notification(.success)
            withAnimation(.spring()) {
                self.isUnlocked = true
            }
        }
    }
    
    private func startLockout(seconds: Int) {
        lockoutSeconds = seconds
        errorMessage = "Terlalu banyak percobaan gagal. Brankas terkunci."
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else { return }
            Task { @MainActor in
                if self.lockoutSeconds > 1 {
                    self.lockoutSeconds -= 1
                } else {
                    self.lockoutSeconds = 0
                    self.errorMessage = nil
                    t.invalidate()
                }
            }
        }
    }
}
