import Foundation
import SwiftData

@Model
final class CaffeineEntry {
    var timestamp: Date
    var milligrams: Double
    var name: String

    init(timestamp: Date = .now, milligrams: Double, name: String) {
        self.timestamp = timestamp
        self.milligrams = milligrams
        self.name = name
    }
}

@Model
final class WaterEntry {
    var timestamp: Date
    var milliliters: Double

    init(timestamp: Date = .now, milliliters: Double) {
        self.timestamp = timestamp
        self.milliliters = milliliters
    }
}

@Model
final class SleepEntry {
    var bedtime: Date
    var wakeTime: Date
    /// Subjective sleep quality, 1 (awful) to 5 (great).
    var quality: Int
    var awakenings: Int
    var notes: String

    init(bedtime: Date, wakeTime: Date, quality: Int = 3, awakenings: Int = 0, notes: String = "") {
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.quality = quality
        self.awakenings = awakenings
        self.notes = notes
    }

    var duration: TimeInterval { wakeTime.timeIntervalSince(bedtime) }

    /// The day whose caffeine and water intake this night of sleep is matched with.
    var day: Date { Bedtime.day(forBedtime: bedtime) }
}
