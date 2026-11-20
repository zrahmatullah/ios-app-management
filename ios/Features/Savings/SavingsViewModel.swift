import Foundation
import SwiftUI

@MainActor
public final class SavingsViewModel: ObservableObject {
    @Published public var savingsList: [Savings] = []
    @Published public var accounts: [Account] = []
    @Published public var selectedProjection: SavingsProjection?
    @Published public var entries: [SavingsEntry] = []
    
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    public init() {}
    
    public func loadSavings() async {
        isLoading = true
        errorMessage = nil
        do {
            async let sTask: [Savings] = GoBridgeService.shared.dispatch(action: "list_savings")
            async let aTask: [Account] = GoBridgeService.shared.dispatch(action: "list_accounts")
            let (s, a) = try await (sTask, aTask)
            self.savingsList = s
            self.accounts = a
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func loadDetails(savingsId: String) async {
        do {
            async let pTask: SavingsProjection = GoBridgeService.shared.dispatch(
                action: "get_savings_projection",
                payload: ["savings_id": savingsId]
            )
            async let eTask: [SavingsEntry] = GoBridgeService.shared.dispatch(
                action: "list_savings_entries",
                payload: ["savings_id": savingsId]
            )
            let (p, e) = try await (pTask, eTask)
            self.selectedProjection = p
            self.entries = e
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    public func createSavings(name: String, target: Int64, deadline: Date, icon: String, color: String) async -> Bool {
        do {
            let payload: [String: Any] = [
                "name": name,
                "target_amount": target,
                "current_amount": 0,
                "deadline": ISO8601DateFormatter().string(from: deadline),
                "icon": icon,
                "color": color
            ]
            let _: Savings = try await GoBridgeService.shared.dispatch(action: "save_savings", payload: payload)
            await loadSavings()
            HapticManager.notification(.success)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    public func addEntry(savingsId: String, accountId: String?, amount: Int64, type: String, note: String) async -> Bool {
        do {
            let payload: [String: Any] = [
                "savings_id": savingsId,
                "account_id": accountId as Any,
                "amount": amount,
                "type": type,
                "note": note,
                "entry_date": ISO8601DateFormatter().string(from: Date())
            ]
            let _: SavingsEntry = try await GoBridgeService.shared.dispatch(action: "add_savings_entry", payload: payload)
            await loadSavings()
            await loadDetails(savingsId: savingsId)
            HapticManager.notification(.success)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
}
