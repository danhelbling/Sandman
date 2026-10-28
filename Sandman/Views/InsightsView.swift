import SwiftUI
import SwiftData
import Charts

struct DaySummary: Identifiable {
    let day: Date
    let caffeineMg: Double
    let caffeineAtBedtimeMg: Double
    let waterML: Double
    let sleep: SleepEntry?

    var id: Date { day }
    var sleepHours: Double? { sleep.map { $0.duration / 3600 } }
}

struct InsightsView: View {
    @Query(sort: \CaffeineEntry.timestamp) private var caffeine: [CaffeineEntry]
    @Query(sort: \WaterEntry.timestamp) private var water: [WaterEntry]
    @Query(sort: \SleepEntry.bedtime) private var sleeps: [SleepEntry]

    @AppStorage(SettingsKey.waterGoalML) private var waterGoal = Defaults.waterGoalML
    @AppStorage(SettingsKey.bedtimeMinutes) private var bedtimeMinutes = Defaults.bedtimeMinutes
    @AppStorage(SettingsKey.halfLifeHours) private var halfLife = Defaults.halfLifeHours
    @AppStorage(SettingsKey.useOunces) private var useOunces = false

    @State private var range = 14

    private var summaries: [DaySummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<range).reversed().compactMap { offset -> DaySummary? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let sleep = sleeps.first { calendar.isDate($0.day, inSameDayAs: day) }
            let bedtime = sleep?.bedtime ?? Bedtime.date(on: day, minutes: bedtimeMinutes)
            let window = bedtime.addingTimeInterval(-36 * 3600)
            let relevantCaffeine = caffeine.filter { $0.timestamp > window && $0.timestamp <= bedtime }
            return DaySummary(
                day: day,
                caffeineMg: caffeine.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
                    .reduce(0) { $0 + $1.milligrams },
                caffeineAtBedtimeMg: Caffeine.remaining(at: bedtime, entries: relevantCaffeine, halfLifeHours: halfLife),
                waterML: water.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
                    .reduce(0) { $0 + $1.milliliters },
                sleep: sleep
            )
        }
    }

    var body: some View {
        NavigationStack {
            let days = summaries
            List {
                Section {
                    Picker("Range", selection: $range) {
                        Text("7 days").tag(7)
                        Text("14 days").tag(14)
                        Text("30 days").tag(30)
                    }
                    .pickerStyle(.segmented)
                }
                patternsSection(days)
                Section("Sleep") { sleepChart(days) }
                Section("Caffeine at bedtime vs. sleep") { scatterChart(days) }
                Section("Caffeine per day") { caffeineChart(days) }
                Section("Water per day") { waterChart(days) }
            }
            .navigationTitle("Insights")
        }
    }

    // MARK: Patterns

    @ViewBuilder
    private func patternsSection(_ days: [DaySummary]) -> some View {
        let nights = days.filter { $0.sleep != nil }
        Section {
            if nights.isEmpty {
                Text("Log a few nights of sleep to start seeing patterns.")
                    .foregroundStyle(.secondary)
            } else {
                comparisonRow(title: "All nights", nights: nights)
                let limit = Defaults.bedtimeCaffeineLimitMg
                let caffeinated = nights.filter { $0.caffeineAtBedtimeMg >= limit }
                let clear = nights.filter { $0.caffeineAtBedtimeMg < limit }
                if caffeinated.count >= 2 && clear.count >= 2 {
                    comparisonRow(title: "≥ \(Int(limit)) mg caffeine at bedtime", nights: caffeinated)
                    comparisonRow(title: "< \(Int(limit)) mg caffeine at bedtime", nights: clear)
                }
                let hydrated = nights.filter { $0.waterML >= waterGoal }
                let dry = nights.filter { $0.waterML < waterGoal }
                if hydrated.count >= 2 && dry.count >= 2 {
                    comparisonRow(title: "Hit water goal", nights: hydrated)
                    comparisonRow(title: "Missed water goal", nights: dry)
                }
            }
        } header: {
            Text("Patterns")
        } footer: {
            Text("Comparisons appear once each group has at least two nights.")
        }
    }

    private func comparisonRow(title: String, nights: [DaySummary]) -> some View {
        let hours = nights.compactMap(\.sleepHours)
        let quality = nights.compactMap { $0.sleep?.quality }
        let avgHours = hours.reduce(0, +) / Double(max(hours.count, 1))
        let avgQuality = Double(quality.reduce(0, +)) / Double(max(quality.count, 1))
        return VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.bold())
            HStack {
                Label(formatDuration(avgHours * 3600), systemImage: "moon.zzz.fill")
                Spacer()
                Label(String(format: "%.1f", avgQuality), systemImage: "star.fill")
                Spacer()
                Text("\(nights.count) night\(nights.count == 1 ? "" : "s")")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: Charts

    private var dayAxis: some AxisContent {
        AxisMarks(values: .stride(by: .day, count: range > 14 ? 7 : (range > 7 ? 2 : 1))) { _ in
            AxisGridLine()
            AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
        }
    }

    private func sleepChart(_ days: [DaySummary]) -> some View {
        Chart(days) { day in
            if let hours = day.sleepHours {
                BarMark(x: .value("Night", day.day, unit: .day), y: .value("Hours", hours))
                    .foregroundStyle(Color.indigo.opacity(0.4 + 0.12 * Double(day.sleep?.quality ?? 3)))
            }
        }
        .chartXAxis { dayAxis }
        .chartYAxisLabel("hours")
        .frame(height: 180)
    }

    private func scatterChart(_ days: [DaySummary]) -> some View {
        Chart(days.filter { $0.sleep != nil }) { day in
            PointMark(x: .value("Caffeine at bedtime", day.caffeineAtBedtimeMg),
                      y: .value("Hours slept", day.sleepHours ?? 0))
                .foregroundStyle(Color.brown)
        }
        .chartXAxisLabel("mg in system at bedtime")
        .chartYAxisLabel("hours")
        .frame(height: 180)
    }

    private func caffeineChart(_ days: [DaySummary]) -> some View {
        Chart(days) { day in
            BarMark(x: .value("Day", day.day, unit: .day), y: .value("mg", day.caffeineMg))
                .foregroundStyle(Color.brown)
        }
        .chartXAxis { dayAxis }
        .chartYAxisLabel("mg")
        .frame(height: 160)
    }

    private func waterChart(_ days: [DaySummary]) -> some View {
        let scale = useOunces ? 1 / Volume.mlPerOunce : 1
        return Chart {
            ForEach(days) { day in
                BarMark(x: .value("Day", day.day, unit: .day), y: .value("Water", day.waterML * scale))
                    .foregroundStyle(Color.blue)
            }
            RuleMark(y: .value("Goal", waterGoal * scale))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Color.secondary)
        }
        .chartXAxis { dayAxis }
        .chartYAxisLabel(useOunces ? "oz" : "ml")
        .frame(height: 160)
    }
}
