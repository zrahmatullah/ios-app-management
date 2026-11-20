import WidgetKit
import SwiftUI

public struct BalanceTimelineProvider: TimelineProvider {
    public func placeholder(in context: Context) -> BalanceWidgetEntry {
        BalanceWidgetEntry(date: Date(), snapshot: LuminaWidgetSnapshot())
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (BalanceWidgetEntry) -> Void) {
        let snapshot = WidgetDataBridge.loadSnapshot()
        completion(BalanceWidgetEntry(date: Date(), snapshot: snapshot))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceWidgetEntry>) -> Void) {
        let snapshot = WidgetDataBridge.loadSnapshot()
        let entry = BalanceWidgetEntry(date: Date(), snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

public struct BalanceWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: LuminaWidgetSnapshot
}

public struct BalanceWidgetView: View {
    let entry: BalanceWidgetEntry
    @Environment(\.widgetFamily) var family
    
    public var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .accessoryRectangular:
            accessoryRectangularView
        case .accessoryCircular:
            accessoryCircularView
        default:
            smallView
        }
    }
    
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "wallet.pass.fill")
                    .foregroundColor(Color(hex: "6366F1"))
                    .font(.system(size: 14))
                Text("Saldo")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text("Rp \(entry.snapshot.totalBalance.formatted())")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Safe-to-Spend™")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "6366F1"))
                Text("Rp \(entry.snapshot.safeToSpendToday.formatted())/hr")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "10B981"))
            }
        }
        .padding(12)
        .background(Color(uiColor: .systemBackground))
    }
    
    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color(hex: "6366F1"))
                    Text("Lumina Finansial")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                
                Text("Rp \(entry.snapshot.totalBalance.formatted())")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                
                HStack(spacing: 12) {
                    Text("+Rp \(entry.snapshot.monthIncome.formatted())")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "10B981"))
                    Text("-Rp \(entry.snapshot.monthExpense.formatted())")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "F43F5E"))
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Uang Aman Belanja")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text("Rp \(entry.snapshot.safeToSpendToday.formatted())")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "10B981"))
                
                Text("Status: Kondisi Aman ✅")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(uiColor: .systemBackground))
    }
    
    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("LUMINA SALDO")
                .font(.system(size: 9, weight: .bold))
            Text("Rp \(entry.snapshot.totalBalance.formatted())")
                .font(.system(size: 14, weight: .bold))
            Text("Aman: Rp \(entry.snapshot.safeToSpendToday.formatted())/hr")
                .font(.system(size: 10))
        }
    }
    
    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 12))
                Text("\(Int(entry.snapshot.totalBalance / 1000))k")
                    .font(.system(size: 10, weight: .bold))
            }
        }
    }
}

public struct LuminaBalanceWidget: Widget {
    public let kind: String = "LuminaBalanceWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BalanceTimelineProvider()) { entry in
            BalanceWidgetView(entry: entry)
        }
        .configurationDisplayName("Saldo & Safe-to-Spend")
        .description("Pantau total saldo dan batas uang belanja harian secara instan.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}
