import SwiftUI
import SwiftData

struct SleepLogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SleepEntry.bedtime, order: .reverse) private var sleeps: [SleepEntry]
    @AppStorage(SettingsKey.bedtimeMinutes) private var bedtimeMinutes = Defaults.bedtimeMinutes

    @State private var showingNewEntry = false
    @State private var editing: SleepEntry?

    var body: some View {
        NavigationStack {
            Group {
                if sleeps.isEmpty {
                    ContentUnavailableView {
                        Label("No sleep logged", systemImage: "bed.double")
                    } description: {
                        Text("Log each night to see how caffeine and water affect your sleep.")
                    } actions: {
                        Button("Log a night") { showingNewEntry = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(sleeps) { entry in
                            Button {
                                editing = entry
                            } label: {
                                SleepRow(entry: entry)
                            }
                            .tint(Color.primary)
                        }
                        .onDelete { offsets in
                            offsets.map { sleeps[$0] }.forEach { context.delete($0) }
                        }
                    }
                }
            }
            .navigationTitle("Sleep")
            .toolbar {
                Button {
                    showingNewEntry = true
                } label: {
                    Label("Log sleep", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                SleepEntryForm(defaultBedtimeMinutes: bedtimeMinutes)
            }
            .sheet(item: $editing) { entry in
                SleepEntryForm(entry: entry, defaultBedtimeMinutes: bedtimeMinutes)
            }
        }
    }
}

struct SleepRow: View {
    let entry: SleepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.day, format: .dateTime.weekday(.wide).month().day())
                    .font(.headline)
                Spacer()
                QualityStars(quality: entry.quality)
            }
            HStack {
                Label(formatDuration(entry.duration), systemImage: "moon.zzz.fill")
                Spacer()
                Text("\(entry.bedtime.formatted(date: .omitted, time: .shortened)) – \(entry.wakeTime.formatted(date: .omitted, time: .shortened))")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            if !entry.notes.isEmpty {
                Text(entry.notes).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

struct QualityStars: View {
    let quality: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= quality ? "star.fill" : "star")
            }
        }
        .font(.caption)
        .foregroundStyle(.yellow)
        .accessibilityElement()
        .accessibilityLabel("Quality \(quality) of 5")
    }
}

struct SleepEntryForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let entry: SleepEntry?
    @State private var bedtime: Date
    @State private var wakeTime: Date
    @State private var quality: Int
    @State private var awakenings: Int
    @State private var notes: String

    init(entry: SleepEntry? = nil, defaultBedtimeMinutes: Int) {
        self.entry = entry
        if let entry {
            _bedtime = State(initialValue: entry.bedtime)
            _wakeTime = State(initialValue: entry.wakeTime)
            _quality = State(initialValue: entry.quality)
            _awakenings = State(initialValue: entry.awakenings)
            _notes = State(initialValue: entry.notes)
        } else {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
            let bed = Bedtime.date(on: yesterday, minutes: defaultBedtimeMinutes)
            _bedtime = State(initialValue: bed)
            _wakeTime = State(initialValue: max(bed, min(bed.addingTimeInterval(8 * 3600), .now)))
            _quality = State(initialValue: 3)
            _awakenings = State(initialValue: 0)
            _notes = State(initialValue: "")
        }
    }

    private var isValid: Bool {
        wakeTime > bedtime && wakeTime.timeIntervalSince(bedtime) < 24 * 3600
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Went to bed", selection: $bedtime)
                    DatePicker("Woke up", selection: $wakeTime)
                    LabeledContent("Time asleep", value: isValid ? formatDuration(wakeTime.timeIntervalSince(bedtime)) : "—")
                }
                Section("How did you sleep?") {
                    HStack {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                quality = i
                            } label: {
                                Image(systemName: i <= quality ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(.yellow)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    Stepper("Woke up \(awakenings) time\(awakenings == 1 ? "" : "s")", value: $awakenings, in: 0...20)
                }
                Section("Notes") {
                    TextField("Dreams, stress, late meal…", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(entry == nil ? "Log sleep" : "Edit sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        if let entry {
            entry.bedtime = bedtime
            entry.wakeTime = wakeTime
            entry.quality = quality
            entry.awakenings = awakenings
            entry.notes = notes
        } else {
            context.insert(SleepEntry(bedtime: bedtime, wakeTime: wakeTime, quality: quality,
                                      awakenings: awakenings, notes: notes))
        }
        dismiss()
    }
}
