import Foundation

enum SettingsKey {
    static let waterGoalML = "waterGoalML"
    static let bedtimeMinutes = "bedtimeMinutes"
    static let halfLifeHours = "caffeineHalfLifeHours"
    static let useOunces = "useOunces"
}

enum Defaults {
    static let waterGoalML = 2500.0
    /// 10:30 PM, as minutes after midnight.
    static let bedtimeMinutes = 22 * 60 + 30
    static let halfLifeHours = 5.0
    /// Caffeine still in your system at bedtime above this level is flagged as likely to disturb sleep.
    static let bedtimeCaffeineLimitMg = 50.0
}

enum Bedtime {
    /// The target bedtime for the night starting on `day`. Bedtimes before noon are treated as after midnight.
    static func date(on day: Date, minutes: Int, calendar: Calendar = .current) -> Date {
        var start = calendar.startOfDay(for: day)
        if minutes < 12 * 60 {
            start = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        }
        return calendar.date(byAdding: .minute, value: minutes, to: start) ?? start
    }

    /// The day a bedtime belongs to, so going to bed at 1 AM still counts as the previous day's night.
    static func day(forBedtime bedtime: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: bedtime.addingTimeInterval(-12 * 3600))
    }
}

enum Volume {
    static let mlPerOunce = 29.5735

    static func format(_ ml: Double, ounces: Bool) -> String {
        if ounces {
            return "\(Int((ml / mlPerOunce).rounded())) oz"
        }
        if ml >= 1000 {
            return String(format: "%.1f L", ml / 1000)
        }
        return "\(Int(ml.rounded())) ml"
    }

    static func quickAdds(ounces: Bool) -> [Double] {
        ounces ? [8, 12, 16].map { $0 * mlPerOunce } : [250, 350, 500]
    }
}

func formatDuration(_ seconds: TimeInterval) -> String {
    let minutes = max(0, Int((seconds / 60).rounded()))
    return "\(minutes / 60)h \(minutes % 60)m"
}
