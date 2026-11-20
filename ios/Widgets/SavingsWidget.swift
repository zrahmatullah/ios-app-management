import WidgetKit
import SwiftUI

public struct SavingsTimelineProvider: TimelineProvider {
    public func placeholder(in context: Context) -> SavingsWidgetEntry {
        SavingsWidgetEntry(date: Date(), snapshot: LuminaWidgetSnapshot())
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (SavingsWidgetEntry) -> Void) {
        let snapshot = WidgetDataBridge.loadSnapshot()
        completion(SavingsWidgetEntry(date: Date(), snapshot: snapshot))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<SavingsWidgetEntry>) -> Void) {
        let snapshot = WidgetDataBridge.loadSnapshot()
        let entry = SavingsWidgetEntry(date: Date(), snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

public struct SavingsWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: LuminaWidgetSnapshot
}

public struct SavingsWidgetView: View {
    let entry: SavingsWidgetEntry
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(Color(hex: "F59E0B"))
                    .font(.system(size: 13))
                Text("Celengan")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: CGFloat(entry.snapshot.topSavingsProgress))
                    .stroke(
                        Color(hex: "F59E0B"),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(entry.snapshot.topSavingsProgress * 100))%")
                    .font(.system(size: 12, weight: .black, design: .rounded))
            }
            .frame(width: 50, height: 50)
            
            VStack(spacing: 1) {
                Text(entry.snapshot.topSavingsName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text("Rp \(entry.snapshot.topSavingsCurrent.formatted())")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(uiColor: .systemBackground))
    }
}

public struct LuminaSavingsWidget: Widget {
    public let kind: String = "LuminaSavingsWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SavingsTimelineProvider()) { entry in
            SavingsWidgetView(entry: entry)
        }
        .configurationDisplayName("Celengan Impian")
        .description("Pantau progres celengan dan target tabungan Anda.")
        .supportedFamilies([.systemSmall])
    }
}
