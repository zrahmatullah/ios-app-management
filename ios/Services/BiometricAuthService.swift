import Foundation
import LocalAuthentication

public final class BiometricAuthService {
    public static let shared = BiometricAuthService()
    
    private init() {}
    
    public enum BiometricType {
        case none
        case touchID
        case faceID
    }
    
    public func getBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }
    
    /// Authenticates user using Face ID, Touch ID, or device passcode fallback
    public func authenticate(reason: String = "Buka Lumina untuk mengakses data pribadi Anda") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Batal"
        
        var error: NSError?
        // Fallback to passcode if biometrics not available or fails
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            do {
                return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            } catch {
                print("[Biometric] Authentication failed: \(error)")
                return false
            }
        }
        return true // No lock on device
    }
}
