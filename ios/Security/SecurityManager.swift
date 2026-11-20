import Foundation
import CryptoKit

// MARK: - OWASP MASVS-AUTH: Security Manager & Brute Force Protection
public final class SecurityManager {
    public static let shared = SecurityManager()
    
    private let saltKey = "lumina_vault_salt"
    private let hashKey = "lumina_vault_hash"
    private let profileNameKey = "lumina_vault_username"
    
    // Brute-force throttling state
    private let maxFailedAttempts = 5
    private let lockoutDurationSeconds: TimeInterval = 30
    
    private init() {}
    
    /// Checks whether user has already registered a local master account
    public var isAccountRegistered: Bool {
        KeychainManager.load(key: hashKey) != nil
    }
    
    /// Gets stored profile name
    public var profileName: String {
        if let data = KeychainManager.load(key: profileNameKey), let name = String(data: data, encoding: .utf8) {
            return name
        }
        return "Pengguna Lumina"
    }
    
    /// Registers a new Master Account with Salted SHA-256 Passcode
    public func registerMasterAccount(name: String, passcode: String) -> Bool {
        guard passcode.count >= 4 else { return false }
        
        // Generate 32-byte cryptographically secure random salt
        var salt = Data(count: 32)
        let result = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        guard result == errSecSuccess else { return false }
        
        let hash = computeHash(passcode: passcode, salt: salt)
        
        let s1 = KeychainManager.save(key: saltKey, data: salt)
        let s2 = KeychainManager.save(key: hashKey, data: hash)
        let s3 = KeychainManager.save(key: profileNameKey, data: name.data(using: .utf8) ?? Data())
        
        return s1 && s2 && s3
    }
    
    /// Verifies entered passcode against stored hash with brute-force protection
    public func verifyPasscode(passcode: String) -> (success: Bool, remainingLockout: Int) {
        // Check if currently locked out
        if let lockoutUntil = UserDefaults.standard.object(forKey: "lumina_lockout_until") as? Date {
            if Date() < lockoutUntil {
                let remaining = Int(lockoutUntil.timeIntervalSinceNow)
                return (false, max(1, remaining))
            } else {
                UserDefaults.standard.removeObject(forKey: "lumina_lockout_until")
                UserDefaults.standard.set(0, forKey: "lumina_failed_attempts")
            }
        }
        
        guard let salt = KeychainManager.load(key: saltKey),
              let storedHash = KeychainManager.load(key: hashKey) else {
            return (false, 0)
        }
        
        let inputHash = computeHash(passcode: passcode, salt: salt)
        if inputHash == storedHash {
            // Reset failed counter
            UserDefaults.standard.set(0, forKey: "lumina_failed_attempts")
            return (true, 0)
        } else {
            // Increment failed attempts
            let attempts = UserDefaults.standard.integer(forKey: "lumina_failed_attempts") + 1
            UserDefaults.standard.set(attempts, forKey: "lumina_failed_attempts")
            
            if attempts >= maxFailedAttempts {
                let lockoutDate = Date().addingTimeInterval(lockoutDurationSeconds)
                UserDefaults.standard.set(lockoutDate, forKey: "lumina_lockout_until")
                return (false, Int(lockoutDurationSeconds))
            }
            return (false, 0)
        }
    }
    
    private func computeHash(passcode: String, salt: Data) -> Data {
        var dataToHash = salt
        dataToHash.append(passcode.data(using: .utf8) ?? Data())
        let digest = SHA256.hash(data: dataToHash)
        return Data(digest)
    }
}
