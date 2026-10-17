import SwiftUI
import Charts

/// A private record of reported days, Support visits, and changes the person notices.
struct RecoveryTimelineView: View {
    @Environment(AppModel.self) private var model
    @State private var showLiveCrystal = false

    var body: some View {
        ZStack {
            AmbientBackground(progress: model.dawnProgress())

            ScrollView {
                VStack(spacing: 22) {
                    title
                    summaryRow
                    observationsSection
                    cravingHeatmapSection
                    moneyChart
                    timelineSection
                    calendarSection
                    liveCrystalButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 130)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showLiveCrystal) {
            liveCrystalSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Your path")
                .font(Theme.display(38))
                .foregroundStyle(Theme.ink)
            Text("What you've noticed along the way.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var liveCrystalButton: some View {
        Button {
            Haptics.soft()
            showLiveCrystal = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkle")
                    .foregroundStyle(Theme.amberInk)
                Text("View the living crystal")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.mutedInk)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.paper))
        }
        .buttonStyle(.plain)
    }

    private var liveCrystalSheet: some View {
        ZStack {
            Theme.indigo.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("A little more light, day by day.")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(Theme.paper)
                    .padding(.top, 26)
                CrystalRockView(progress: model.dawnProgress(), mode: .support)
                    .frame(height: 290)
                    .accessibilityLabel("Slowly turning faceted crystal")
                Text("A live 3D study of your changing crystal")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.paper.opacity(0.58))
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            StatTile(icon: "banknote.fill", value: model.moneySaved().asMoney, label: "est. saved")
            StatTile(icon: "wind", value: "\(model.data.urgeStarts.count)", label: "support opens")
            StatTile(icon: "clock", value: "\(model.daysClean())", label: "current stretch")
        }
    }

    // MARK: What the person has actually noticed

    private var observationsSection: some View {
        let checkIns = model.data.dailyCheckIns
        let symptoms = checkIns.compactMap(\.symptom)
        let counts = Dictionary(grouping: symptoms, by: { $0 }).mapValues(\.count)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("What you've noticed")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if !checkIns.isEmpty {
                    Text("\(checkIns.count) check-in\(checkIns.count == 1 ? "" : "s")")
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(Theme.mutedInk)
                }
            }
            if counts.isEmpty {
                Text("Sleep, mood, appetite, or cravings on your mind? Add one optional note at check-in and notice your own pattern here.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(counts.keys.sorted(), id: \.self) { symptom in
                    HStack(spacing: 10) {
                        Circle().fill(Theme.amberLight).frame(width: 8, height: 8)
                        Text(symptom)
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("noted \(counts[symptom, default: 0])×")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.mutedInk)
                    }
                }
                Text("These are your entries, not a diagnosis or a forecast.")
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.mutedInk)
            }
        }
        .padding(18)
        .background(GlassCard())
    }

    // MARK: Money chart

    private var moneyChart: some View {
        let now = Date()
        let elapsedDays = Int(max(0, now.timeIntervalSince(model.data.quitDate)) / 86_400)
        let days = min(30, max(1, elapsedDays))
        let start = max(model.data.quitDate, now.addingTimeInterval(-Double(days) * 86_400))
        let points = (0...days).map { day in
            let date = min(now, start.addingTimeInterval(Double(day) * 86_400))
            return MoneyPoint(day: day, amount: model.moneySaved(asOf: date))
        }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Estimated saved since you began")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.cream)
            Chart(points) { point in
                AreaMark(x: .value("Day", point.day), y: .value("Saved", point.amount))
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.mint.opacity(0.45), Theme.mint.opacity(0.02)],
                                       startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("Day", point.day), y: .value("Saved", point.amount))
                    .foregroundStyle(Theme.amber)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel { if let d = value.as(Int.self) { Text("d\(d)").foregroundStyle(Theme.mutedInk) } }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) { Text(v.asMoney).foregroundStyle(Theme.mutedInk) }
                    }
                }
            }
            .frame(height: 150)
            Text("Based on the weekly amount you entered; days with reported use are excluded. Recent 30 days shown, not actual purchases.")
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(GlassCard())
    }

    // MARK: Recovery timeline

    private var timelineSection: some View {
        let currentDays = model.fractionalDaysClean()
        let longestDays = model.longestClearStretchDays()
        return VStack(alignment: .leading, spacing: 0) {
            Text("Moments along the way")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.cream)
                .padding(.bottom, 14)

            ForEach(Array(Milestones.all.enumerated()), id: \.element.id) { index, milestone in
                let reached = longestDays >= milestone.day
                let reachedBefore = reached && currentDays < milestone.day
                TimelineRow(milestone: milestone, reached: reached,
                            reachedBefore: reachedBefore,
                            isLast: index == Milestones.all.count - 1)
            }
        }
        .padding(18)
        .background(GlassCard())
    }

    // MARK: Support pattern

    private var cravingHeatmapSection: some View {
        let buckets = model.cravingHeatmap()
        let maxCount = Double(max(1, buckets.map(\.count).max() ?? 0))
        let hasData = buckets.contains { $0.count > 0 }
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("When you opened Support")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.cream)
                Spacer()
                Text("30 days")
                    .font(Theme.rounded(11, .bold))
                    .foregroundStyle(Theme.mutedInk)
            }
            if hasData {
                VStack(spacing: 10) {
                    ForEach(buckets) { bucket in
                        HeatmapRow(bucket: bucket, maxCount: maxCount)
                    }
                }
            } else {
                Text("Support visits appear here after you use it. Opening Support isn't a report of a craving or a prediction.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
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
            HStack(spacing: 16) {
                Label("Reported no use", systemImage: "circle.fill")
                    .foregroundStyle(Theme.amberInk)
                Label("Reported use", systemImage: "circle")
                    .foregroundStyle(Theme.mutedInk)
            }
            .font(Theme.rounded(10))
            Text("Unmarked days remain blank; Clearing won't guess what happened.")
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.mutedInk)
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

private struct HeatmapRow: View {
    let bucket: HeatmapBucket
    let maxCount: Double

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: bucket.window.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(bucket.peak ? Theme.gold : Theme.mint)
                    .frame(width: 22)
                Text(bucket.window.label)
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.cream)
                Spacer()
                Text("\(bucket.count)")
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.mutedInk)
                    .monospacedDigit()
            }
            ProgressView(value: Double(bucket.count), total: maxCount)
                .tint(bucket.peak ? Theme.gold : Theme.mint)
        }
    }
}

private struct TimelineRow: View {
    let milestone: Milestone
    let reached: Bool
    let reachedBefore: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(reached ? Theme.amberLight : Theme.canvas)
                        .frame(width: 34, height: 34)
                    Image(systemName: reached ? milestone.icon : "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(reached ? Theme.ink : Theme.mutedInk)
                }
                if !isLast {
                    Rectangle()
                        .fill(reached ? Theme.amber.opacity(0.38) : Theme.hairline)
                        .frame(width: 2)
                        .frame(minHeight: 34)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(milestone.title)
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(reached ? Theme.ink : Theme.mutedInk)
                if reachedBefore {
                    Text("Reached on an earlier stretch")
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(Theme.amberInk)
                }
                Text(milestone.fact)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 18)
            Spacer(minLength: 0)
        }
    }
}

/// Current-month grid; only days the person explicitly reported are marked.
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
                        .foregroundStyle(Theme.mutedInk)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.frame(height: 34) }
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) ?? today
                    DayCell(date: date,
                            status: status(on: date, calendar: cal),
                            isToday: cal.isDateInToday(date))
                }
            }
        }
    }

    private func status(on date: Date, calendar: Calendar) -> UseStatus? {
        model.data.dailyCheckIns.last(where: { calendar.isDate($0.date, inSameDayAs: date) })?.status
    }
}

private struct DayCell: View {
    let date: Date
    let status: UseStatus?
    let isToday: Bool

    var body: some View {
        let day = Calendar.current.component(.day, from: date)
        Text("\(day)")
            .font(Theme.rounded(13, isToday ? .bold : .medium))
            .foregroundStyle(status == .clear ? Theme.ink : Theme.mutedInk)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                Circle().fill(status == .clear ? Theme.amberLight.opacity(0.72) : .clear)
            )
            .overlay(
                Circle().stroke(isToday ? Theme.amber : .clear, lineWidth: 1.5)
            )
            .overlay(alignment: .bottom) {
                if status == .used {
                    Circle().fill(Theme.mutedInk).frame(width: 4, height: 4).offset(y: 1)
                }
            }
            .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)), \(statusLabel)")
    }

    private var statusLabel: String {
        switch status {
        case .clear: "reported no use"
        case .used: "reported use"
        case nil: "no check-in"
        }
    }
}
