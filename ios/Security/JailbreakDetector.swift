import Foundation

// MARK: - OWASP MASVS-RESILIENCE: Jailbreak & Tampering Detection
public enum JailbreakDetector {
    public static func isDeviceCompromised() -> Bool {
        #if targetEnvironment(simulator)
        return false // Simulators have custom test files
        #else
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        
        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check sandbox integrity: attempting to write outside sandbox
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            return true // Successfully wrote outside sandbox
        } catch {
            // Normal sandboxed behavior
        }
        
        return false
        #endif
    }
}
