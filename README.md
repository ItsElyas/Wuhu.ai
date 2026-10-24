# Wuhu (HealthTracker)

A clean iOS SwiftUI dashboard for daily and weekly health stats, workouts, an interactive Body Map with healing tips for injuries, a wellness chatbot, and Vitality Age scoring.

## Features

- **Daily / Weekly dashboard** — steps (goal ring), heart rate, sleep stages, active and resting calories, Swift Charts, pull to refresh
- **Workouts** — log and review sessions, merge HealthKit imports, muscles-worked picker
- **Workout Hub** — Start Workout → Running or Lifting → today's regimen (or any day / free workout) → log sets (weight, reps, done) or run segments (miles, time, avg HR; pace calculated) → Finish. Finished sessions go to the Workout Log history and also feed Wear & Tear, weekly powerlifting stats, and the WSL estimate.
- **Active workout bubble + Live Activity** — minimize the logger (chevron) and a draggable timer bubble floats over the app; tap it to resume. While a workout is running, a Live Activity (Lock Screen + Dynamic Island, `WuhuWidgets` extension) keeps the timer and progress visible with the app closed; tapping it reopens the logger (`wuhu://workout/<id>`).
- **Body Map** — 2D (always) and 3D RealityKit wear-and-tear map; mark parts healthy / sore / injured
- **Heal tips** — tap a **red (injured)** region to open recovery recommendations for that body part (wellness guidance only, not medical advice)
- **Home** — greeting, WSL Score (tier names; Bron until ranking exists), sleep, Wear & Tear, Weekly Stats, and Workout Hub (see `docs/UI_SPEC.md`). Live Health on device; dashes when data is missing.
- **Weekly Stats** — Home pushes Weekly Performance. The default mode is running (`docs/design/weekly-running-reference.png`). Powerlifting is the other layout (`docs/design/weekly-powerlifting-reference.png`). Debug builds can switch them in Settings → Debug → Weekly preview.
- **Chat** — Gemini-backed orchestrator when configured (wear updates from natural language + wellness check-in); local keyword fallback otherwise
- **Vitality Age, Recovery, Effort, Sleep Score** — optional LLM scoring from a compact Health JSON snapshot, with an on-device calculator fallback. WSL Score opens the breakdown and shows the current tier. The Home screen is locked to light mode so the mesh matches the reference.

Home uses Plus Jakarta Sans (ExtraBold, Bold, SemiBold, Medium, Regular). See [Fonts](#fonts) and `docs/design/home-reference.png`.

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

### 2. Get the code (local-first)

This project is developed **locally** for now. GitHub/Origin remotes come later — see [SYNC.md](SYNC.md).

```bash
cd /path/to/this/repo
open Wuhu.xcodeproj
```

Then scheme **Wuhu** → iOS 18 simulator → **Cmd+R**. See [RUN.md](RUN.md) and [MIGRATION.md](MIGRATION.md) (entry point: `Wuhu/App/WuhuApp.swift`).

When you add GitHub later:

```bash
git clone <GITHUB_REPO_URL>
cd Wuhu
open Wuhu.xcodeproj
```

### 3. Add your API key (optional)
```bash
cp Secrets.example.xcconfig Secrets.xcconfig
open -e Secrets.xcconfig
```
Paste your key next to `LLM_API_KEY`, then save. Skip this to use the local fallback scoring.

### Gemini chat

Chat uses **`ChatOrchestrator`** with Google Gemini (`GeminiChatClient`, Interactions API `POST /v1beta/interactions`, stateless) and the **Wuhu master system prompt v1.1** (`Wuhu/Features/Chat/WuhuMasterPrompt.swift`).

1. Copy `Secrets.example.xcconfig` → `Secrets.xcconfig`.
2. Set **`GEMINI_API_KEY`** (Google AI Studio → Get API key). `GEMINI_MODEL` (default `gemini-3.8-flash`) and `GEMINI_BASE_URL` are optional overrides.
3. Enable **Settings → Send health summary to AI** (same consent as scoring). Optional: **Chat wellness check-in** for the opening message.

When configured, the FAB chat sheet shows orchestrator phases: `reading your past health...`, `thinking...`, `updating...`. The compact health context goes in Gemini's `systemInstruction`. Body Map changes come back as an `update_wear_and_tear` function call, which the app validates before applying (the model can only mark a part injured if your message says so).

Without a Gemini key, **`ChatLocalFallback`** handles keyword wear updates (e.g. “right knee hurts”).

To change the persona, edit **`WuhuMasterPrompt.text`** and rebuild. Keep `ChatSystemPrompt.toolRules`: it maps the prompt's "backend functions" to the app's real context and the `update_wear_and_tear` tool. To switch providers later, add a client that conforms to `ChatLLMProviding` and return it from `ChatOrchestrator.make`.

MyNetDiary keys in the same file:

- `MYNETDIARY_API_KEY` — partner or proxy key. Leave the placeholder in place if you do not have one.
- `MYNETDIARY_BASE_URL` — defaults to `https://api.mynetdiary.com`.
- `MYNETDIARY_USER_ID` — only if that API requires a linked user. Leave it empty otherwise.

Do not commit `Secrets.xcconfig`.

### 4. Open the project
```bash
open Wuhu.xcodeproj
```

### 5. Configure signing (first time only)
1. Click the project in the left sidebar, then the **Wuhu** target.
2. Open **Signing & Capabilities**.
3. Select your **Team** and keep **Automatically manage signing** on.
4. Confirm the Bundle Identifier is `com.elyaskhoubach.wuhu` (unique so Apple can register it for your team). If Xcode still says the identifier is unavailable, change it to something only you own, for example `com.<yourname>.wuhu`, then press Enter and wait for signing to refresh.
5. Confirm the **HealthKit** capability is listed. Add it with "+ Capability" if not.
6. If the red signing error persists: Xcode → Settings → Accounts → add your Apple ID → Download Manual Profiles, then re-select the Team on the target.

### 6. Run on the simulator
1. Pick an iPhone simulator (iOS 18+) in the top toolbar.
2. Press Cmd+R.
3. The simulator has little Apple Health data; Home and Weekly screens may show dashes until you add samples or use a device.
4. Open **Body Map** from the Dashboard to mark body-part status manually.

### 7. Run on a real iPhone (recommended)
1. Connect your iPhone and trust the computer.
2. Enable Developer Mode on the phone (Settings → Privacy & Security → Developer Mode).
3. Select your phone in the toolbar and press Cmd+R.
4. Allow **Apple Health** access when Wuhu asks. If metrics stay empty, open **Settings → Health → Data Access & Devices → Wuhu** and turn categories on, then pull to refresh on Home.

### 8. Run the tests
```bash
xcodebuild test -scheme Wuhu -destination 'platform=iOS Simulator,name=iPhone 16'
```
(Or press Cmd+U in Xcode. If that simulator name does not exist, run `xcrun simctl list devices available` and use one that does.)

## Apple Health data vs demo mode

- By default Wuhu reads **Apple Health (HealthKit)** on device.
- **Demo mode** (Settings → Demo → Demo mode) switches the whole app to sample data for demos and judging, no Health access or API keys needed: 30 days of steps, sleep, heart rate, HRV, calories and macros; Health-style runs with distance; a Workout Log with 4 lifting and 3 running sessions (real sets, weights, splits, pace); Body Map statuses including an injured right knee for the heal tips; and a sample chat exchange. Demo data lives in a separate in-memory store, so real data is untouched and returns when demo mode is turned off. Anything logged during the demo is discarded.
- The first launch asks for read access. Grant steps, heart rate, HRV, sleep, active and resting energy, dietary energy and macros, walking and running distance, and workouts.
- If access is denied or a day has no samples, values show as **`--`** with a short caption (DEBUG builds also show a data-source banner on Home).
- **Simulator:** HealthKit samples are sparse; use a **physical iPhone** for real metrics.
- Home **Burned** is active plus resting energy from Health. Home **In** is calories eaten (MyNetDiary API or Health dietary energy). Weekly Running uses the last seven days from Health workouts and aggregates.
- **SwiftUI previews** and unit tests may still use fixture types; they are not used at runtime.

## MyNetDiary

MyNetDiary does not publish a REST API for a person's food diary. The commercial [Food Database](https://www.mynetdiary.com/food-database.html) license is a food-search catalog (about $40,000 the first year), not the calories you logged.

Wuhu still has a client for a partner-shaped diary summary:

`GET {MYNETDIARY_BASE_URL}/v1/diary/days?days=7&userId={MYNETDIARY_USER_ID}`

Headers: `Authorization: Bearer <MYNETDIARY_API_KEY>` and `X-API-Key`. Expected JSON:

```json
{ "days": [ { "date": "2026-10-24", "calories": 2100, "protein": 140, "carbs": 220, "fat": 70 } ] }
```

That route is not an official public endpoint. It runs only when `MYNETDIARY_API_KEY` is set to a real key. Otherwise, and if the call fails, intake comes from Apple Health `dietaryEnergyConsumed` (plus protein, carbohydrate, and fat when those samples exist). Turn on MyNetDiary → Apple Health sync so those samples are written. Today's intake is kept in memory and refreshes when you pull to refresh on Home. Settings shows **MyNetDiary** status.

## How the AI scoring works

1. `HealthKitManager` (or the mock provider) loads aggregates.
2. `HealthSnapshotBuilder` builds a compact JSON snapshot (schema version 1), including non-healthy `body_status` entries (notes omitted).
3. `ScoringService` sends the snapshot to an LLM (if consented and a key is present) or uses `MockScoringService` / `VitalityAgeCalculator`.
4. Results are validated, clamped, cached per day in SwiftData, and shown on the Vitality tab.
5. Chat reuses the same snapshot and `ScoreResult` as context.

If the LLM fails or AI is disabled, scores are **estimated locally**.

## Project structure

```
Wuhu/
├── App/                 # Entry, environment, settings
├── Core/
│   ├── HealthKit/       # Provider protocol, live + mock
│   ├── Nutrition/       # MyNetDiary client and Health intake fallback
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
xcodebuild test -scheme Wuhu -destination 'platform=iOS Simulator,name=iPhone 16'
```

Coverage includes Vitality Age boundaries, snapshot JSON, score decoding, workout de-duplication, Body Map load rules, and healing tip coverage for every body part.

## Privacy

- Reads (with permission): steps, heart rate, resting HR, HRV, sleep, active and resting energy, dietary energy and macros, walking and running distance, workouts, date of birth / profile fields.
- Data stays on device unless you opt in to AI scoring.
- When AI is on, only the compact snapshot JSON is sent — no raw samples, names, emails, or device IDs.
- Turn AI off in Settings (or decline the one-time consent sheet).
- Debug builds include **View data sent** to inspect the exact JSON.

## Troubleshooting

| Issue | What to try |
|---|---|
| Empty dashboard or dashes | Grant Health access on a device, or turn on Settings → Demo mode. Denied access stays blank. |
| MyNetDiary shows Not connected | Expected without a partner key. Enable MyNetDiary's Apple Health sync, then pull to refresh. |
| Bundle identifier / signing errors | Bundle ID must be unique. Default is `com.elyaskhoubach.wuhu`. Change it under Signing & Capabilities if Apple says it is unavailable, pick your Team, keep Automatic signing on. Clean build folder (Product → Clean Build Folder) and run again. |
| Signing errors | Select your Team under Signing & Capabilities; ensure you are signed into Xcode with an Apple ID (Settings → Accounts) |
| Stale compile errors after agent edits | Open **`Wuhu.xcodeproj`** (not the removed HealthTracker project). See [MIGRATION.md](MIGRATION.md). |
| Simulator name not found | `xcrun simctl list devices available` and update the destination |
| AI scores missing | Optional — local fallback still works; check `Secrets.xcconfig` |
| Body Map 3D blank | Use the 2D map toggle; procedural body is the default without `body.usdz` |

## Disclaimer

HealthTracker is a **wellness tool for motivation**. It is not a medical device and does not diagnose, treat, or cure any condition. Healing tips for injured body parts are general wellness ideas only — see a clinician or physical therapist for personal medical advice.

## Fonts

Home text uses [Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans) by Tokotype (The Plus Jakarta Sans Project Authors). The faces are Regular, Medium, SemiBold, Bold, and ExtraBold, registered under the PostScript names `PlusJakartaSans-Regular`, `PlusJakartaSans-Medium`, `PlusJakartaSans-SemiBold`, `PlusJakartaSans-Bold`, and `PlusJakartaSans-ExtraBold`. Files live in `Wuhu/Resources/Fonts/` with the SIL Open Font License in `Wuhu/Resources/Fonts/OFL.txt`. If a face does not load, that style falls back to the system font at the same size and weight. SF Symbols stay on the system font.

## License and asset credits

- App source: see repository license (or all rights reserved by the project author if none is set).
- Plus Jakarta Sans: Copyright 2020 The Plus Jakarta Sans Project Authors (https://github.com/tokotype/PlusJakartaSans). Licensed under the SIL Open Font License, Version 1.1. See [Wuhu/Resources/Fonts/OFL.txt](Wuhu/Resources/Fonts/OFL.txt).
- Procedural 3D body: original to this project. Optional USDZ instructions and license notes: [Wuhu/Resources/Models/LICENSE.md](Wuhu/Resources/Models/LICENSE.md).
