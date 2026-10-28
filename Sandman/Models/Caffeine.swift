import Foundation

struct DrinkPreset: Identifiable {
    let name: String
    let milligrams: Double
    let symbol: String
    var id: String { name }

    static let all: [DrinkPreset] = [
        DrinkPreset(name: "Coffee", milligrams: 95, symbol: "mug.fill"),
        DrinkPreset(name: "Espresso", milligrams: 63, symbol: "cup.and.saucer.fill"),
        DrinkPreset(name: "Cold brew", milligrams: 200, symbol: "takeoutbag.and.cup.and.straw.fill"),
        DrinkPreset(name: "Black tea", milligrams: 47, symbol: "leaf.fill"),
        DrinkPreset(name: "Green tea", milligrams: 28, symbol: "leaf"),
        DrinkPreset(name: "Energy drink", milligrams: 80, symbol: "bolt.fill"),
        DrinkPreset(name: "Cola", milligrams: 34, symbol: "bubbles.and.sparkles.fill"),
    ]
}

/// Caffeine is modelled as first-order elimination: each dose halves every `halfLifeHours`.
enum Caffeine {
    static let referenceDoseMg = 95.0

    static func remaining(at date: Date, entries: [CaffeineEntry], halfLifeHours: Double) -> Double {
        entries.reduce(0) { total, entry in
            let elapsed = date.timeIntervalSince(entry.timestamp)
            guard elapsed >= 0 else { return total }
            return total + entry.milligrams * pow(0.5, elapsed / (halfLifeHours * 3600))
        }
    }

    /// The latest time a cup of coffee can be drunk and still leave you under `limitMg` at `bedtime`,
    /// or nil if you're already over the limit.
    static func lastCall(bedtime: Date, entries: [CaffeineEntry], halfLifeHours: Double, limitMg: Double) -> Date? {
        let headroom = limitMg - remaining(at: bedtime, entries: entries, halfLifeHours: halfLifeHours)
        guard headroom > 0 else { return nil }
        guard referenceDoseMg > headroom else { return bedtime }
        let hoursBefore = halfLifeHours * log2(referenceDoseMg / headroom)
        return bedtime.addingTimeInterval(-hoursBefore * 3600)
    }
}
