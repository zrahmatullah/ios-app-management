import Foundation
import SwiftUI

@MainActor
public final class FinanceViewModel: ObservableObject {
    @Published public var accounts: [Account] = []
    @Published public var categories: [Category] = []
    @Published public var transactions: [Transaction] = []
    @Published public var budgets: [Budget] = []
    
    @Published public var selectedAccountId: String? = nil
    @Published public var selectedCategoryId: String? = nil
    @Published public var searchQuery: String = ""
    @Published public var selectedTabType: String = "ALL" // ALL, INCOME, EXPENSE
    
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    public init() {}
    
    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let accsTask: [Account] = GoBridgeService.shared.dispatch(action: "list_accounts")
            async let catsTask: [Category] = GoBridgeService.shared.dispatch(action: "list_categories")
            async let txsTask: [Transaction] = GoBridgeService.shared.dispatch(
                action: "filter_transactions",
                payload: [
                    "category_id": selectedCategoryId ?? "",
                    "account_id": selectedAccountId ?? "",
                    "query": searchQuery
                ]
            )
            async let budgetsTask: [Budget] = GoBridgeService.shared.dispatch(action: "list_budgets")
            
            let (accs, cats, txs, bdg) = try await (accsTask, catsTask, txsTask, budgetsTask)
            self.accounts = accs
            self.categories = cats
            self.transactions = txs
            self.budgets = bdg
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func createTransaction(
        accountId: String,
        toAccountId: String?,
        categoryId: String?,
        amount: Int64,
        type: String,
        note: String,
        date: Date
    ) async -> Bool {
        do {
            let payload: [String: Any] = [
                "account_id": accountId,
                "to_account_id": toAccountId as Any,
                "category_id": categoryId as Any,
                "amount": amount,
                "type": type,
                "note": note,
                "transaction_date": ISO8601DateFormatter().string(from: date)
            ]
            let _: Transaction = try await GoBridgeService.shared.dispatch(action: "create_transaction", payload: payload)
            await loadData()
            HapticManager.notification(.success)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    public func deleteTransaction(id: String) async {
        do {
            let _: Bool = try await GoBridgeService.shared.dispatch(
                action: "delete_transaction",
                payload: ["id": id]
            )
            await loadData()
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
