import SwiftUI
import Charts

/// Retention beyond the streak — turns "a counter" into "a story of my body healing":
/// money chart, the recovery timeline, and a clean-day calendar.
struct RecoveryTimelineView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            AmbientBackground(progress: model.dawnProgress())

            ScrollView {
                VStack(spacing: 22) {
                    title
                    summaryRow
                    moneyChart
                    timelineSection
                    calendarSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 130)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var title: some View {
        HStack {
            Text("Your recovery")
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.cream)
            Spacer()
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            StatTile(icon: "banknote.fill", value: model.moneySaved().asMoney, label: "saved so far")
            StatTile(icon: "wind", value: "\(model.urgesBeaten)", label: "urges beaten")
            StatTile(icon: "flame.fill", value: "\(model.daysClean())", label: "day streak")
        }
    }

    // MARK: Money chart

    private var moneyChart: some View {
        let days = max(1, model.daysClean())
        let perDay = model.data.weeklySpend / 7
        let points = (0...days).map { MoneyPoint(day: $0, amount: perDay * Double($0)) }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Money back in your pocket")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.cream)
            Chart(points) { point in
                AreaMark(x: .value("Day", point.day), y: .value("Saved", point.amount))
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.mint.opacity(0.45), Theme.mint.opacity(0.02)],
                                       startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("Day", point.day), y: .value("Saved", point.amount))
                    .foregroundStyle(Theme.brightMint)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel { if let d = value.as(Int.self) { Text("d\(d)").foregroundStyle(Theme.cream.opacity(0.4)) } }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) { Text(v.asMoney).foregroundStyle(Theme.cream.opacity(0.4)) }
                    }
                }
            }
            .frame(height: 150)
        }
        .padding(18)
        .background(GlassCard())
    }

    // MARK: Recovery timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What's happening in your body")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.cream)
                .padding(.bottom, 14)

            ForEach(Array(Milestones.all.enumerated()), id: \.element.id) { index, milestone in
                let reached = model.fractionalDaysClean() >= milestone.day
                TimelineRow(milestone: milestone, reached: reached,
                            isLast: index == Milestones.all.count - 1)
            }
        }
        .padding(18)
        .background(GlassCard())
    }

    // MARK: Calendar

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(monthTitle)
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.cream)
            CleanCalendar()
        }
        .padding(18)
        .background(GlassCard())
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
    }()

    private var monthTitle: String {
        Self.monthFormatter.string(from: Date())
    }
}

private struct MoneyPoint: Identifiable {
    let day: Int
    var id: Int { day }
    let amount: Double
}

private struct TimelineRow: View {
    let milestone: Milestone
    let reached: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(reached ? Theme.mint : Color.white.opacity(0.08))
                        .frame(width: 34, height: 34)
                    Image(systemName: reached ? milestone.icon : "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(reached ? Color(hex: 0x06241A) : Theme.cream.opacity(0.4))
                }
                if !isLast {
                    Rectangle()
                        .fill(reached ? Theme.mint.opacity(0.4) : Color.white.opacity(0.08))
                        .frame(width: 2)
                        .frame(minHeight: 34)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(milestone.title)
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(reached ? Theme.cream : Theme.cream.opacity(0.45))
                Text(milestone.fact)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.cream.opacity(reached ? 0.6 : 0.35))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 18)
            Spacer(minLength: 0)
        }
    }
}

/// Current-month grid; days inside the clean streak glow.
private struct CleanCalendar: View {
    @Environment(AppModel.self) private var model
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let symbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        let cal = Calendar.current
        let today = Date()
        let comps = cal.dateComponents([.year, .month], from: today)
        let firstOfMonth = cal.date(from: comps) ?? today
        let firstWeekday = cal.component(.weekday, from: firstOfMonth) - 1
        let daysInMonth = cal.range(of: .day, in: .month, for: today)?.count ?? 31

        return VStack(spacing: 8) {
            HStack {
                ForEach(0..<7, id: \.self) { i in
                    Text(symbols[i])
                        .font(Theme.rounded(11, .semibold))
                        .foregroundStyle(Theme.cream.opacity(0.35))
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.frame(height: 34) }
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) ?? today
                    DayCell(date: date,
                            clean: isClean(date, cal: cal, today: today),
                            isToday: cal.isDateInToday(date))
                }
            }
        }
    }

    private func isClean(_ date: Date, cal: Calendar, today: Date) -> Bool {
        let start = cal.startOfDay(for: model.cleanStart)
        let day = cal.startOfDay(for: date)
        return day >= start && day <= cal.startOfDay(for: today)
    }
}

private struct DayCell: View {
    let date: Date
    let clean: Bool
    let isToday: Bool

    var body: some View {
        let day = Calendar.current.component(.day, from: date)
        Text("\(day)")
            .font(Theme.rounded(13, isToday ? .bold : .medium))
            .foregroundStyle(clean ? Color(hex: 0x06241A) : Theme.cream.opacity(0.4))
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                Circle().fill(clean
                              ? AnyShapeStyle(LinearGradient(colors: [Theme.brightMint, Theme.mint],
                                                             startPoint: .top, endPoint: .bottom))
                              : AnyShapeStyle(Color.clear))
            )
            .overlay(
                Circle().stroke(Theme.gold, lineWidth: isToday ? 1.5 : 0)
            )
    }
}
