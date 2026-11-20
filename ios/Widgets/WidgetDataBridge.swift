import Foundation
import WidgetKit

// MARK: - Shared Data Model for Widgets
public struct LuminaWidgetSnapshot: Codable, Sendable {
    public let totalBalance: Int64
    public let monthIncome: Int64
    public let monthExpense: Int64
    public let safeToSpendToday: Int64
    public let safeToSpendStatus: String // SAFE, WARNING, OVERSPENT
    public let topSavingsName: String
    public let topSavingsProgress: Double
    public let topSavingsCurrent: Int64
    public let topSavingsTarget: Int64
    public var habits: [WidgetHabitSnapshot]
    public let lastUpdated: Date
    
    public init(
        totalBalance: Int64 = 5750000,
        monthIncome: Int64 = 8500000,
        monthExpense: Int64 = 3200000,
        safeToSpendToday: Int64 = 85000,
        safeToSpendStatus: String = "SAFE",
        topSavingsName: String = "Dana Darurat",
        topSavingsProgress: Double = 0.30,
        topSavingsCurrent: Int64 = 4500000,
        topSavingsTarget: Int64 = 15000000,
        habits: [WidgetHabitSnapshot] = [
            WidgetHabitSnapshot(id: "h1", title: "Minum Air 2L", isDone: true, streak: 4),
            WidgetHabitSnapshot(id: "h2", title: "Membaca Buku", isDone: false, streak: 7)
        ],
        lastUpdated: Date = Date()
    ) {
        self.totalBalance = totalBalance
        self.monthIncome = monthIncome
        self.monthExpense = monthExpense
        self.safeToSpendToday = safeToSpendToday
        self.safeToSpendStatus = safeToSpendStatus
        self.topSavingsName = topSavingsName
        self.topSavingsProgress = topSavingsProgress
        self.topSavingsCurrent = topSavingsCurrent
        self.topSavingsTarget = topSavingsTarget
        self.habits = habits
        self.lastUpdated = lastUpdated
    }
}

public struct WidgetHabitSnapshot: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public var isDone: Bool
    public var streak: Int
    
    public init(id: String, title: String, isDone: Bool, streak: Int) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.streak = streak
    }
}

// MARK: - App Group Data Bridge
public enum WidgetDataBridge {
    public static let appGroupId = "group.com.lumina.personalapp"
    private static let snapshotKey = "lumina_widget_cached_snapshot"
    
    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
    }
    
    /// Called by main app to publish current metrics to iOS Widgets
    public static func saveSnapshot(_ snapshot: LuminaWidgetSnapshot) {
        if let encoded = try? JSONEncoder().encode(snapshot) {
            sharedDefaults?.set(encoded, forKey: snapshotKey)
            // Trigger iOS to refresh all active Lumina widgets
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    /// Called by Widget Extension to load the latest snapshot
    public static func loadSnapshot() -> LuminaWidgetSnapshot {
        if let data = sharedDefaults?.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(LuminaWidgetSnapshot.self, from: data) {
            return snapshot
        }
        // Return default placeholder snapshot
        return LuminaWidgetSnapshot()
    }
    
    /// Toggles a habit directly from widget (iOS 17 AppIntent background action)
    public static func toggleHabit(id: String) {
        var current = loadSnapshot()
        if let index = current.habits.firstIndex(where: { $0.id == id }) {
            current.habits[index].isDone.toggle()
            if current.habits[index].isDone {
                current.habits[index].streak += 1
            } else {
                current.habits[index].streak = max(0, current.habits[index].streak - 1)
            }
            saveSnapshot(current)
        }
    }
}
