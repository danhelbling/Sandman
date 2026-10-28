import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CaffeineEntry.timestamp, order: .reverse) private var caffeine: [CaffeineEntry]
    @Query(sort: \WaterEntry.timestamp, order: .reverse) private var water: [WaterEntry]
    @Query(sort: \SleepEntry.bedtime, order: .reverse) private var sleeps: [SleepEntry]

    @AppStorage(SettingsKey.waterGoalML) private var waterGoal = Defaults.waterGoalML
    @AppStorage(SettingsKey.bedtimeMinutes) private var bedtimeMinutes = Defaults.bedtimeMinutes
    @AppStorage(SettingsKey.halfLifeHours) private var halfLife = Defaults.halfLifeHours
    @AppStorage(SettingsKey.useOunces) private var useOunces = false

    @State private var showingCustomCaffeine = false
    @State private var showingCustomWater = false
    @State private var showingSleepForm = false
    @State private var logCount = 0

    private var todaysCaffeine: [CaffeineEntry] {
        caffeine.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var todaysWater: [WaterEntry] {
        water.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    /// Anything from the last day can still be in your system.
    private var recentCaffeine: [CaffeineEntry] {
        let cutoff = Date.now.addingTimeInterval(-36 * 3600)
        return caffeine.filter { $0.timestamp > cutoff }
    }

    private var lastNight: SleepEntry? {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        return sleeps.first { Calendar.current.isDate($0.day, inSameDayAs: yesterday) }
    }

    var body: some View {
        NavigationStack {
            List {
                lastNightSection
                caffeineSection
                waterSection
                logSection
            }
            .navigationTitle("Today")
            .sensoryFeedback(.success, trigger: logCount)
            .sheet(isPresented: $showingCustomCaffeine) {
                CustomCaffeineSheet { name, mg, time in
                    logCaffeine(name: name, mg: mg, at: time)
                }
            }
            .sheet(isPresented: $showingCustomWater) {
                CustomWaterSheet(useOunces: useOunces) { ml, time in
                    logWater(ml, at: time)
                }
            }
            .sheet(isPresented: $showingSleepForm) {
                SleepEntryForm(defaultBedtimeMinutes: bedtimeMinutes)
            }
        }
    }

    // MARK: Sections

    private var lastNightSection: some View {
        Section("Last night") {
            if let lastNight {
                SleepRow(entry: lastNight)
            } else {
                Button {
                    showingSleepForm = true
                } label: {
                    Label("Log last night's sleep", systemImage: "moon.zzz.fill")
                }
            }
        }
    }

    private var caffeineSection: some View {
        Section {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                caffeineStatus(now: timeline.date)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96))], spacing: 8) {
                ForEach(DrinkPreset.all) { preset in
                    Button {
                        logCaffeine(name: preset.name, mg: preset.milligrams, at: .now)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: preset.symbol)
                            Text(preset.name).font(.caption)
                            Text("\(Int(preset.milligrams)) mg").font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.brown)
                }
                Button {
                    showingCustomCaffeine = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Custom").font(.caption)
                        Text(" ").font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Caffeine")
        }
    }

    @ViewBuilder
    private func caffeineStatus(now: Date) -> some View {
        // Until 6 AM we're still in last night; after that, show tonight's bedtime.
        let evening = Calendar.current.startOfDay(for: now.addingTimeInterval(-6 * 3600))
        let bedtime = Bedtime.date(on: evening, minutes: bedtimeMinutes)
        let inSystem = Caffeine.remaining(at: now, entries: recentCaffeine, halfLifeHours: halfLife)
        let atBedtime = Caffeine.remaining(at: bedtime, entries: recentCaffeine, halfLifeHours: halfLife)
        let limit = Defaults.bedtimeCaffeineLimitMg
        let total = todaysCaffeine.reduce(0) { $0 + $1.milligrams }

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatView(title: "Today", value: "\(Int(total)) mg")
                StatView(title: "In your system", value: "\(Int(inSystem.rounded())) mg")
                if bedtime > now {
                    StatView(title: "At bedtime", value: "\(Int(atBedtime.rounded())) mg",
                             tint: atBedtime > limit ? .orange : .primary)
                }
            }

            CaffeineCurveChart(entries: recentCaffeine, now: now, bedtime: bedtime,
                               halfLifeHours: halfLife, limitMg: limit)

            if bedtime > now {
                if let lastCall = Caffeine.lastCall(bedtime: bedtime, entries: recentCaffeine,
                                                    halfLifeHours: halfLife, limitMg: limit),
                   lastCall > now {
                    Label("Last call for a coffee: \(lastCall.formatted(date: .omitted, time: .shortened))",
                          systemImage: "clock")
                        .font(.subheadline)
                } else {
                    Label("More caffeine today will likely disturb your sleep.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var waterSection: some View {
        let total = todaysWater.reduce(0) { $0 + $1.milliliters }
        return Section("Water") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Volume.format(total, ounces: useOunces))
                        .font(.title2.bold())
                    Text("of \(Volume.format(waterGoal, ounces: useOunces))")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if total >= waterGoal {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                }
                ProgressView(value: min(total, waterGoal), total: waterGoal)
                    .tint(.blue)
            }
            .padding(.vertical, 4)

            HStack {
                ForEach(Volume.quickAdds(ounces: useOunces), id: \.self) { ml in
                    Button("+\(Volume.format(ml, ounces: useOunces))") {
                        logWater(ml, at: .now)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .frame(maxWidth: .infinity)
                }
                Button {
                    showingCustomWater = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private var logSection: some View {
        if !todaysCaffeine.isEmpty {
            Section("Caffeine log") {
                ForEach(todaysCaffeine) { entry in
                    HStack {
                        Text(entry.name)
                        Spacer()
                        Text("\(Int(entry.milligrams)) mg").foregroundStyle(.secondary)
                        Text(entry.timestamp, style: .time).foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    offsets.map { todaysCaffeine[$0] }.forEach { context.delete($0) }
                }
            }
        }
        if !todaysWater.isEmpty {
            Section("Water log") {
                ForEach(todaysWater) { entry in
                    HStack {
                        Text(Volume.format(entry.milliliters, ounces: useOunces))
                        Spacer()
                        Text(entry.timestamp, style: .time).foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    offsets.map { todaysWater[$0] }.forEach { context.delete($0) }
                }
            }
        }
    }

    // MARK: Actions

    private func logCaffeine(name: String, mg: Double, at time: Date) {
        context.insert(CaffeineEntry(timestamp: time, milligrams: mg, name: name))
        logCount += 1
    }

    private func logWater(_ ml: Double, at time: Date) {
        context.insert(WaterEntry(timestamp: time, milliliters: ml))
        logCount += 1
    }
}

struct StatView: View {
    let title: String
    let value: String
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
