import SwiftUI

struct CustomCaffeineSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, Double, Date) -> Void

    @State private var name = ""
    @State private var milligrams = 100.0
    @State private var time = Date.now

    var body: some View {
        NavigationStack {
            Form {
                TextField("Drink", text: $name)
                Stepper(value: $milligrams, in: 5...500, step: 5) {
                    LabeledContent("Caffeine", value: "\(Int(milligrams)) mg")
                }
                DatePicker("Time", selection: $time, in: ...Date.now)
            }
            .navigationTitle("Add caffeine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        onSave(trimmed.isEmpty ? "Caffeine" : trimmed, milligrams, time)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct CustomWaterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let useOunces: Bool
    let onSave: (Double, Date) -> Void

    @State private var amount: Double
    @State private var time = Date.now

    init(useOunces: Bool, onSave: @escaping (Double, Date) -> Void) {
        self.useOunces = useOunces
        self.onSave = onSave
        _amount = State(initialValue: useOunces ? 8 : 250)
    }

    private var range: ClosedRange<Double> { useOunces ? 1...64 : 25...2000 }
    private var step: Double { useOunces ? 1 : 25 }

    var body: some View {
        NavigationStack {
            Form {
                Stepper(value: $amount, in: range, step: step) {
                    LabeledContent("Amount", value: "\(Int(amount)) \(useOunces ? "oz" : "ml")")
                }
                DatePicker("Time", selection: $time, in: ...Date.now)
            }
            .navigationTitle("Add water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(useOunces ? amount * Volume.mlPerOunce : amount, time)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
