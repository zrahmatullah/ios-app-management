import WidgetKit
import SwiftUI
import AppIntents

public struct HabitTimelineProvider: TimelineProvider {
    public func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(date: Date(), snapshot: LuminaWidgetSnapshot())
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> Void) {
        let snapshot = WidgetDataBridge.loadSnapshot()
        completion(HabitWidgetEntry(date: Date(), snapshot: snapshot))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> Void) {
        let snapshot = WidgetDataBridge.loadSnapshot()
        let entry = HabitWidgetEntry(date: Date(), snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

public struct HabitWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: LuminaWidgetSnapshot
}

public struct HabitWidgetView: View {
    let entry: HabitWidgetEntry
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color(hex: "FF3B30"))
                    Text("Habit Tracker")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                Spacer()
                Text("Hari Ini")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 6) {
                ForEach(entry.snapshot.habits.prefix(3)) { habit in
                    HStack {
                        #if canImport(AppIntents)
                        if #available(iOS 17.0, *) {
                            Button(intent: ToggleHabitIntent(habitId: habit.id)) {
                                Image(systemName: habit.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(habit.isDone ? Color(hex: "10B981") : .secondary)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Image(systemName: habit.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(habit.isDone ? Color(hex: "10B981") : .secondary)
                                .font(.system(size: 16))
                        }
                        #else
                        Image(systemName: habit.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(habit.isDone ? Color(hex: "10B981") : .secondary)
                            .font(.system(size: 16))
                        #endif
                        
                        Text(habit.title)
                            .font(.system(size: 11, design: .rounded))
                            .strikethrough(habit.isDone)
                            .foregroundColor(habit.isDone ? .secondary : .primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("🔥 \(habit.streak)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "FF3B30"))
                    }
                    .padding(.vertical, 1)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .systemBackground))
    }
}

public struct LuminaHabitWidget: Widget {
    public let kind: String = "LuminaHabitWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitTimelineProvider()) { entry in
            HabitWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Tracker Interaktif")
        .description("Centang kebiasaan harian Anda langsung dari layar depan tanpa membuka aplikasi.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
