import WidgetKit
import SwiftUI

// MARK: - Color helper (widget target is its own module)

private extension Color {
    init(_ hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: 1)
    }
    static let cream = Color(0xF4F1E8)
    static let mint = Color(0x86E5B0)
    static let brightMint = Color(0xB8F2C9)
    static let deepGreen = Color(0x0C211B)
}

// MARK: - Timeline

struct ClearingEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetShared.Snapshot

    var days: Int { max(0, Int(date.timeIntervalSince(snapshot.cleanStart) / 86_400)) }
    var moneySaved: Double {
        snapshot.weeklySpend / (7 * 86_400) * max(0, date.timeIntervalSince(snapshot.cleanStart))
    }
    var moneyLabel: String { "$\(Int(moneySaved))" }
}

struct ClearingProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClearingEntry {
        ClearingEntry(date: Date(), snapshot: WidgetShared.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClearingEntry) -> Void) {
        completion(ClearingEntry(date: Date(), snapshot: WidgetShared.read() ?? WidgetShared.sample))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClearingEntry>) -> Void) {
        let snap = WidgetShared.read() ?? WidgetShared.sample
        let now = Date()
        let entry = ClearingEntry(date: now, snapshot: snap)
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: - Views

struct ClearingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ClearingEntry

    var body: some View {
        switch family {
        case .accessoryCircular:    circular
        case .accessoryRectangular: rectangular
        case .accessoryInline:      Text("\(entry.days) days clear").widgetAccentable()
        default:                    home
        }
    }

    // Home / StandBy
    private var home: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: "leaf.fill").font(.system(size: 12, weight: .bold))
                Text("CLEARING").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1)
            }
            .foregroundStyle(Color.mint)
            Spacer(minLength: 0)
            Text("\(entry.days)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.cream)
            Text(entry.days == 1 ? "day clear" : "days clear")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.cream.opacity(0.6))
            Spacer(minLength: 0)
            Label(entry.moneyLabel + " saved", systemImage: "banknote.fill")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.brightMint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(0x143A2C), Color(0x07150F)],
                           startPoint: .top, endPoint: .bottom)
        }
    }

    // Lock Screen circular
    private var circular: some View {
        Gauge(value: min(1, Double(entry.days % 30) / 30.0)) {
            Image(systemName: "leaf.fill")
        } currentValueLabel: {
            Text("\(entry.days)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
        .widgetAccentable()
        .containerBackground(.clear, for: .widget)
    }

    // Lock Screen rectangular
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Clearing", systemImage: "leaf.fill")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .widgetAccentable()
            Text("\(entry.days) days clear")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            Text(entry.moneyLabel + " saved")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Bundle

struct ClearingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ClearingWidget", provider: ClearingProvider()) { entry in
            ClearingWidgetView(entry: entry)
        }
        .configurationDisplayName("Clearing")
        .description("Your days clear and money saved — always in view.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct ClearingWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClearingWidget()
    }
}
