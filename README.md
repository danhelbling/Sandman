# Sandman

A sleep hygiene app for iPhone. Log caffeine and water during the day, log your sleep that night, and see how they relate.

## Features

- **Today**: one-tap logging for common drinks (coffee, espresso, cold brew, tea, energy drinks, cola) or a custom amount.
  - Estimates how much caffeine is in your system now and how much will be left at your target bedtime, with a chart of the curve through the day.
  - Shows a **last call** time: the latest you can have a coffee and still be under 50 mg at bedtime.
  - Water progress toward your daily goal, with quick-add buttons.
- **Sleep**: log bedtime, wake time, a 1–5 quality rating, how many times you woke up, and notes. Tap a night to edit it.
- **Insights** (7, 14 or 30 days): charts of sleep, caffeine and water per day, a scatter plot of caffeine at bedtime against hours slept, and averages comparing:
  - nights with ≥ 50 mg of caffeine still in your system at bedtime vs. nights under 50 mg
  - days you hit your water goal vs. days you missed it
- **Settings**: target bedtime, water goal, ml or oz, and your caffeine half-life.

Each night's sleep is matched to the day you went to bed. Going to bed at 1 AM still counts as the previous day.

## Caffeine model

Each dose decays exponentially: `remaining = mg × 0.5^(hours elapsed / half-life)`. The default half-life is 5 hours. You can change it in Settings, because it varies a lot from person to person.

## Running it

Requirements: Xcode 16 or later, targeting iOS 17 or later. Uses SwiftUI, SwiftData and Swift Charts, with no third-party dependencies.

1. Open `Sandman.xcodeproj`.
2. Choose the **Sandman** scheme and a simulator, then press Run.
3. To run on your own iPhone, pick your team under *Signing & Capabilities*. A free Apple ID works. You may also need to change the bundle identifier.

All data stays on the device in SwiftData.

## Ideas for next steps

- Import sleep automatically from Apple Health or Apple Watch (HealthKit)
- A notification when your caffeine last call is coming up
- Home screen widgets for quick logging
