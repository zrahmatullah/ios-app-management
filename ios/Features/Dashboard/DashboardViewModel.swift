import Foundation
import SwiftUI

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var summary: DashboardSummary?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    public init() {}
    
    public func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        do {
            let res: DashboardSummary = try await GoBridgeService.shared.dispatch(action: "get_dashboard_summary")
            self.summary = res
            
            // Sync to iOS Widgets via App Group & reload WidgetKit timelines
            syncWidgetSnapshot(from: res)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func syncWidgetSnapshot(from summary: DashboardSummary) {
        let habitSnapshots = summary.habitsToday.map {
            WidgetHabitSnapshot(id: $0.id, title: $0.title, isDone: $0.isDoneToday, streak: $0.streakCurrent)
        }
        let topSavings = summary.topSavings.first
        let snapshot = LuminaWidgetSnapshot(
            totalBalance: summary.totalBalance,
            monthIncome: summary.monthIncome,
            monthExpense: summary.monthExpense,
            safeToSpendToday: 85000,
            safeToSpendStatus: "SAFE",
            topSavingsName: topSavings?.name ?? "Dana Darurat",
            topSavingsProgress: topSavings?.progress ?? 0.30,
            topSavingsCurrent: topSavings?.currentAmount ?? 4500000,
            topSavingsTarget: topSavings?.targetAmount ?? 15000000,
            habits: habitSnapshots,
            lastUpdated: Date()
        )
        WidgetDataBridge.saveSnapshot(snapshot)
    }
    
    public func toggleHabit(habitId: String) async {
        do {
            let _: [String: Bool] = try await GoBridgeService.shared.dispatch(
                action: "toggle_habit_today",
                payload: ["habit_id": habitId]
            )
            await loadDashboard()
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    public var greeting: LocalizedStringKey {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 11 {
            return "Selamat Pagi,"
        } else if hour < 15 {
            return "Selamat Siang,"
        } else if hour < 18 {
            return "Selamat Sore,"
        } else {
            return "Selamat Malam,"
        }
    }
}
