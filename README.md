# HealthTracker

A clean iOS SwiftUI dashboard for daily and weekly health stats, workouts, an interactive Body Map with healing tips for injuries, a wellness chatbot, and Vitality Age scoring.

## Features

- **Daily / Weekly dashboard** — steps (goal ring), heart rate, sleep stages, active and resting calories, Swift Charts, pull to refresh
- **Workouts** — log and review sessions, merge HealthKit imports, muscles-worked picker
- **Body Map** — 2D (always) and 3D RealityKit wear-and-tear map; mark parts healthy / sore / injured
- **Heal tips** — tap a **red (injured)** region to open recovery recommendations for that body part (wellness guidance only, not medical advice)
- **Chat** — health Q&A grounded in your latest snapshot and scores
- **Vitality Age, Readiness, Effort, Sleep Score** — optional LLM scoring from a compact Health JSON snapshot, with an on-device calculator fallback

## Screenshots or demo GIF

_Placeholder — capture from Simulator after first run (Dashboard, Body Map with a red knee, Vitality Age)._

## Requirements

See [REQUIREMENTS.md](REQUIREMENTS.md) for versions. Short list: macOS + Xcode with iOS 18 SDK, optional LLM API key.

## Setup and Run

### 1. Install prerequisites
1. Install Xcode from the Mac App Store and open it once to accept the license.
2. Install command line tools:
   ```bash
   xcode-select --install
   ```
3. (Optional) Install SwiftLint:
   ```bash
   brew install swiftlint
   ```

### 2. Get the code
```bash
# Preferred (Origin)
origin repo clone elyas-khoubach/Wuhu
cd Wuhu
```

Or see [SYNC.md](SYNC.md) for pull/visibility details and troubleshooting when Xcode shows stale errors.

```bash
git clone <REPO_URL>
cd HealthTracker
```

### 3. Add your API key (optional)
```bash
cp Secrets.example.xcconfig Secrets.xcconfig
open -e Secrets.xcconfig
```
Paste your key next to `LLM_API_KEY`, then save. Skip this to use the local fallback scoring.

### 4. Open the project
```bash
open HealthTracker.xcodeproj
```

### 5. Configure signing (first time only)
1. Click the project in the left sidebar, then the **HealthTracker** target.
2. Open **Signing & Capabilities**.
3. Select your **Team** and keep **Automatically manage signing** on.
4. Confirm the Bundle Identifier is `com.elyaskhoubach.wuhu` (unique so Apple can register it for your team). If Xcode still says the identifier is unavailable, change it to something only you own, for example `com.<yourname>.wuhu`, then press Enter and wait for signing to refresh.
5. Confirm the **HealthKit** capability is listed. Add it with "+ Capability" if not.
6. If the red signing error persists: Xcode → Settings → Accounts → add your Apple ID → Download Manual Profiles, then re-select the Team on the target.

### 6. Run on the simulator
1. Pick an iPhone simulator (iOS 18+) in the top toolbar.
2. Press Cmd+R.
3. You should see the Dashboard with Daily and Weekly tabs. Mock Data is on by default so cards are filled.
4. Open **Body Map** from the Dashboard. Tap the red (injured) knee to see **How to heal** tips.

### 7. (Optional) Run on a real iPhone for real health data
1. Connect your iPhone and trust the computer.
2. Enable Developer Mode on the phone (Settings → Privacy & Security → Developer Mode).
3. Select your phone in the toolbar and press Cmd+R.
4. In the app Settings, turn **off** Mock Data and allow Health access when prompted.

### 8. Run the tests
```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16'
```
(Or press Cmd+U in Xcode. If that simulator name does not exist, run `xcrun simctl list devices available` and use one that does.)

## Using mock data vs real Apple Health data

- **Mock (default):** Settings → Use mock data, or scheme launch argument `-useMockData` (enabled in the shared scheme).
- Mock mode populates Daily, Weekly, Workouts, Body Map (yellow + one red part), Vitality Age, and Chat with no Health data and no API key.
- **Real HealthKit:** turn off Mock Data, grant read access for steps, heart rate, HRV, sleep, energy, workouts, and date of birth.

## How the AI scoring works

1. `HealthKitManager` (or the mock provider) loads aggregates.
2. `HealthSnapshotBuilder` builds a compact JSON snapshot (schema version 1), including non-healthy `body_status` entries (notes omitted).
3. `ScoringService` sends the snapshot to an LLM (if consented and a key is present) or uses `MockScoringService` / `VitalityAgeCalculator`.
4. Results are validated, clamped, cached per day in SwiftData, and shown on the Vitality tab.
5. Chat reuses the same snapshot and `ScoreResult` as context.

If the LLM fails or AI is disabled, scores are **estimated locally**.

## Project structure

```
HealthTracker/
├── App/                 # Entry, environment, settings
├── Core/
│   ├── HealthKit/       # Provider protocol, live + mock
│   ├── Models/          # Stats, workouts, chat, body status
│   ├── Scoring/         # Snapshot, LLM + local Vitality Age
│   └── Services/        # ChatService
├── Features/
│   ├── Dashboard/
│   ├── Workouts/
│   ├── Chat/
│   ├── BodyMap/         # 2D/3D map, heal tips, load mapper
│   ├── Vitality/
│   └── Settings/
├── DesignSystem/
└── Resources/Models/    # LICENSE + optional body.usdz
```

## Running tests

```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16'
```

Coverage includes Vitality Age boundaries, snapshot JSON, score decoding, workout de-duplication, Body Map load rules, and healing tip coverage for every body part.

## Privacy

- Reads (with permission): steps, heart rate, resting HR, HRV, sleep, active/basal energy, workouts, date of birth / profile fields.
- Data stays on device unless you opt in to AI scoring.
- When AI is on, only the compact snapshot JSON is sent — no raw samples, names, emails, or device IDs.
- Turn AI off in Settings (or decline the one-time consent sheet).
- Debug builds include **View data sent** to inspect the exact JSON.

## Troubleshooting

| Issue | What to try |
|---|---|
| Empty dashboard | Enable Mock Data, or grant Health access on a device |
| Bundle identifier / signing errors | Bundle ID must be unique. Default is `com.elyaskhoubach.wuhu`. Change it under Signing & Capabilities if Apple says it is unavailable, pick your Team, keep Automatic signing on. Clean build folder (Product → Clean Build Folder) and run again. |
| Signing errors | Select your Team under Signing & Capabilities; ensure you are signed into Xcode with an Apple ID (Settings → Accounts) |
| Simulator name not found | `xcrun simctl list devices available` and update the destination |
| AI scores missing | Optional — local fallback still works; check `Secrets.xcconfig` |
| Body Map 3D blank | Use the 2D map toggle; procedural body is the default without `body.usdz` |

## Disclaimer

HealthTracker is a **wellness tool for motivation**. It is not a medical device and does not diagnose, treat, or cure any condition. Healing tips for injured body parts are general wellness ideas only — see a clinician or physical therapist for personal medical advice.

## License and asset credits

- App source: see repository license (or all rights reserved by the project author if none is set).
- Procedural 3D body: original to this project. Optional USDZ instructions and license notes: [HealthTracker/Resources/Models/LICENSE.md](HealthTracker/Resources/Models/LICENSE.md).
