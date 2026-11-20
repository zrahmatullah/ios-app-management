import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Entry
public struct LuminaWidgetEntry: TimelineEntry {
    public let date: Date
    public let totalBalance: Int64
    public let safeToSpendToday: Int64
    public let habits: [WidgetHabitItem]
}

public struct WidgetHabitItem: Identifiable, Codable {
    public let id: String
    public let title: String
    public let isDone: Bool
    public let streak: Int
}

// MARK: - Widget Provider
public struct LuminaTimelineProvider: TimelineProvider {
    public func placeholder(in context: Context) -> LuminaWidgetEntry {
        LuminaWidgetEntry(
            date: Date(),
            totalBalance: 5750000,
            safeToSpendToday: 85000,
            habits: [
                WidgetHabitItem(id: "1", title: "Minum Air 2L", isDone: true, streak: 4),
                WidgetHabitItem(id: "2", title: "Baca Buku", isDone: false, streak: 7)
            ]
        )
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (LuminaWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<LuminaWidgetEntry>) -> Void) {
        let entry = LuminaWidgetEntry(
            date: Date(),
            totalBalance: 5750000,
            safeToSpendToday: 85000,
            habits: [
                WidgetHabitItem(id: "1", title: "Minum Air 2L", isDone: true, streak: 4),
                WidgetHabitItem(id: "2", title: "Baca Buku", isDone: false, streak: 7)
            ]
        )
        // Refresh every 1 hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Balance & Safe-to-Spend Small Widget View
public struct LuminaBalanceWidgetView: View {
    let entry: LuminaWidgetEntry
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(hex: "6366F1"))
                Text("Lumina")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Saldo")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary)
                Text("Rp \(entry.totalBalance.formatted())")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Uang Aman Hari Ini")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundColor(.secondary)
                Text("Rp \(entry.safeToSpendToday.formatted())")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(Color(hex: "10B981"))
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Interactive Habit Medium Widget View
public struct LuminaHabitWidgetView: View {
    let entry: LuminaWidgetEntry
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Habit Tracker Hari Ini")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                Spacer()
                Text("🔥 Aktif")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Color(hex: "FF3B30"))
            }
            
            ForEach(entry.habits) { habit in
                HStack {
                    Image(systemName: habit.isDone ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(habit.isDone ? Color(hex: "10B981") : .secondary)
                    Text(habit.title)
                        .font(.system(.caption, design: .rounded))
                        .strikethrough(habit.isDone)
                    Spacer()
                    Text("\(habit.streak) hari")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }
}
