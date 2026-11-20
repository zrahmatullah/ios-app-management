import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
public final class SettingsViewModel: ObservableObject {
    @AppStorage("lumina_theme") public var appTheme: String = "auto"
    @AppStorage("lumina_biometric_enabled") public var isBiometricEnabled: Bool = false
    @AppStorage("lumina_accent_color") public var accentColor: String = "indigo"
    
    @Published public var backupJsonUrl: URL?
    @Published public var csvUrl: URL?
    @Published public var showingShareSheet: Bool = false
    @Published public var shareItems: [Any] = []
    
    @Published public var errorMessage: String?
    @Published public var successMessage: String?
    
    public init() {}
    
    public func toggleBiometric(enable: Bool) async {
        let authenticated = await BiometricAuthService.shared.authenticate(
            reason: enable ? "Aktifkan kunci biometrik" : "Nonaktifkan kunci biometrik"
        )
        if authenticated {
            isBiometricEnabled = enable
            HapticManager.notification(.success)
        } else {
            // Revert state
            isBiometricEnabled = !enable
            HapticManager.notification(.error)
        }
    }
    
    public func exportBackupJson() async {
        do {
            let res: [String: String] = try await GoBridgeService.shared.dispatch(action: "export_backup_json")
            if let json = res["backup_json"] {
                let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("Lumina_Backup_\(Date().formatted(.iso8601.year().month().day())).json")
                try json.write(to: tempUrl, atomically: true, encoding: .utf8)
                
                self.shareItems = [tempUrl]
                self.showingShareSheet = true
                HapticManager.notification(.success)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    public func exportTransactionsCSV() async {
        do {
            let res: [String: String] = try await GoBridgeService.shared.dispatch(action: "export_csv")
            if let csv = res["csv_content"] {
                let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("Lumina_Transactions_\(Date().formatted(.iso8601.year().month().day())).csv")
                try csv.write(to: tempUrl, atomically: true, encoding: .utf8)
                
                self.shareItems = [tempUrl]
                self.showingShareSheet = true
                HapticManager.notification(.success)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
