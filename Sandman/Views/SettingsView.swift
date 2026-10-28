import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.waterGoalML) private var waterGoal = Defaults.waterGoalML
    @AppStorage(SettingsKey.bedtimeMinutes) private var bedtimeMinutes = Defaults.bedtimeMinutes
    @AppStorage(SettingsKey.halfLifeHours) private var halfLife = Defaults.halfLifeHours
    @AppStorage(SettingsKey.useOunces) private var useOunces = false

    private var bedtime: Binding<Date> {
        Binding {
            Calendar.current.date(byAdding: .minute, value: bedtimeMinutes,
                                  to: Calendar.current.startOfDay(for: .now)) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            bedtimeMinutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sleep") {
                    DatePicker("Target bedtime", selection: bedtime, displayedComponents: .hourAndMinute)
                }
                Section {
                    Toggle("Use ounces", isOn: $useOunces)
                    Stepper(value: $waterGoal, in: 1000...5000, step: useOunces ? Volume.mlPerOunce * 8 : 250) {
                        LabeledContent("Daily goal", value: Volume.format(waterGoal, ounces: useOunces))
                    }
                } header: {
                    Text("Water")
                }
                Section {
                    Stepper(value: $halfLife, in: 2...10, step: 0.5) {
                        LabeledContent("Half-life", value: String(format: "%.1f h", halfLife))
                    }
                } header: {
                    Text("Caffeine")
                } footer: {
                    Text("Caffeine's half-life averages about 5 hours but ranges from roughly 2 to 10 depending on genetics, pregnancy, medications and smoking. Sandman flags more than \(Int(Defaults.bedtimeCaffeineLimitMg)) mg left in your system at bedtime.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
