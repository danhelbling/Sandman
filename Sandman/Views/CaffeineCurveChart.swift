import SwiftUI
import Charts

/// Estimated caffeine level across the day, from midnight until two hours after bedtime.
struct CaffeineCurveChart: View {
    let entries: [CaffeineEntry]
    let now: Date
    let bedtime: Date
    let halfLifeHours: Double
    let limitMg: Double

    private struct Point: Identifiable {
        let date: Date
        let mg: Double
        var id: Date { date }
    }

    private var points: [Point] {
        let start = Calendar.current.startOfDay(for: min(now, bedtime))
        let end = max(now, bedtime).addingTimeInterval(2 * 3600)
        return stride(from: start.timeIntervalSince1970, through: end.timeIntervalSince1970, by: 600).map {
            let date = Date(timeIntervalSince1970: $0)
            return Point(date: date, mg: Caffeine.remaining(at: date, entries: entries, halfLifeHours: halfLifeHours))
        }
    }

    var body: some View {
        Chart {
            ForEach(points) { point in
                AreaMark(x: .value("Time", point.date), y: .value("Caffeine", point.mg))
                    .foregroundStyle(Color.brown.opacity(0.2))
                LineMark(x: .value("Time", point.date), y: .value("Caffeine", point.mg))
                    .foregroundStyle(Color.brown)
            }
            RuleMark(y: .value("Limit", limitMg))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Color.secondary)
            RuleMark(x: .value("Now", now))
                .foregroundStyle(Color.orange)
            RuleMark(x: .value("Bedtime", bedtime))
                .foregroundStyle(Color.indigo)
                .annotation(position: .top, alignment: .leading) {
                    Image(systemName: "moon.fill").font(.caption2).foregroundStyle(.indigo)
                }
        }
        .chartYAxisLabel("mg")
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .frame(height: 140)
    }
}
