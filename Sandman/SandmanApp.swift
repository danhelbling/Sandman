import SwiftUI
import SwiftData

@main
struct SandmanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CaffeineEntry.self, WaterEntry.self, SleepEntry.self])
    }
}
