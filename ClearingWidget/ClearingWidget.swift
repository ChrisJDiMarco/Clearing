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
    static let cream = Color(0x183126)
    static let mint = Color(0x35A873)
    static let brightMint = Color(0xA8EFC1)
    static let gold = Color(0xC89435)
    static let paper = Color(0xF8F3E8)
    static let paleGreen = Color(0xEAF4EA)
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
    var cleanDays: Double { max(0, date.timeIntervalSince(snapshot.cleanStart) / 86_400) }
    var riskLabel: String { snapshot.riskWindow ?? "Evening" }

    var nextMilestone: Double {
        [1, 3, 7, 14, 30, 60, 90].first { Double($0) > cleanDays }.map(Double.init) ?? 90
    }

    var nextLabel: String {
        nextMilestone == 90 && cleanDays >= 90 ? "Baseline reset" : "Day \(Int(nextMilestone))"
    }

    var milestoneProgress: Double {
        let previous = [0, 1, 3, 7, 14, 30, 60, 90].last { Double($0) <= cleanDays }.map(Double.init) ?? 0
        guard nextMilestone > previous else { return 1 }
        return min(1, max(0, (cleanDays - previous) / (nextMilestone - previous)))
    }
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
        case .systemMedium:         medium
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
                .font(.system(size: 50, weight: .semibold, design: .serif))
                .fontWidth(.condensed)
                .foregroundStyle(Color.cream)
                .monospacedDigit()
            Text(entry.days == 1 ? "day clear" : "days clear")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.cream.opacity(0.6))
            Spacer(minLength: 0)
            Label(entry.moneyLabel + " saved", systemImage: "banknote.fill")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.mint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color.paper, Color.paleGreen],
                           startPoint: .top, endPoint: .bottom)
        }
    }

    private var medium: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Label("CLEARING", systemImage: "leaf.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.mint)
                Spacer(minLength: 0)
                Text("\(entry.days)")
                    .font(.system(size: 58, weight: .semibold, design: .serif))
                    .fontWidth(.condensed)
                    .foregroundStyle(Color.cream)
                    .monospacedDigit()
                Text(entry.days == 1 ? "day clear" : "days clear")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.cream.opacity(0.62))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Next")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.cream.opacity(0.45))
                    Text(entry.nextLabel)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.cream)
                    ProgressView(value: entry.milestoneProgress)
                        .tint(Color.gold)
                }
                Label(entry.riskLabel, systemImage: "moon.haze.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.gold)
                Label(entry.moneyLabel + " saved", systemImage: "banknote.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.mint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color.paper, Color.paleGreen],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
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
