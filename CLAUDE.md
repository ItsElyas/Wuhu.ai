# CLAUDE.md — HealthTracker (iOS / SwiftUI)

Project instructions for AI coding assistants (Cursor, Claude Code). Read this fully before making changes.

## Project Overview

HealthTracker is a simple, clean iOS dashboard app built in Xcode with SwiftUI. It shows daily and weekly health stats, tracks workouts, includes an in-app health chatbot, and computes an original "Vitality Age" score from the user's stats.

**Core features**
1. Dashboard with Daily and Weekly views
2. Step tracker
3. Heart rate (resting + recent)
4. Sleep (duration + stages)
5. Calories (active + resting, optional intake)
6. Chatbot (health Q&A grounded in the user's stats)
7. Workouts sub-screen (log and review workouts)
8. Vitality Age: a single "ego stat" metric derived from the user's own data
9. Body Map: an interactive 3D body where the user taps a body part to mark it as injured (red) or sore / recently worked (yellow)

**Non-goals (do not build unless asked):** accounts/auth, social features, backend sync, Apple Watch app, in-app purchases.

## Tech Stack

- Language: Swift 5.9+
- UI: SwiftUI only (no UIKit unless a SwiftUI API does not exist)
- Min target: iOS 18 (needed for `RealityView` on iOS, used by the Body Map)
- 3D: RealityKit (`RealityView`). Do not use SceneKit; it is deprecated.
- Architecture: MVVM with `@Observable` (Observation framework)
- Data: HealthKit (source of truth for health data), SwiftData (workouts logged in-app, cached summaries, chat history)
- Charts: Swift Charts
- Concurrency: async/await, `@MainActor` for view models. No Combine unless needed.
- Dependencies: none by default. Ask before adding any Swift Package.

## Project Structure

```
HealthTracker/
├── App/
│   └── HealthTrackerApp.swift
├── Core/
│   ├── HealthKit/        # HealthKitManager, queries, authorization
│   ├── Models/           # DailyStats, WeeklyStats, Workout, ChatMessage
│   ├── Scoring/          # VitalityAgeCalculator (pure, testable)
│   └── Services/         # ChatService, protocols
├── Features/
│   ├── Dashboard/        # DashboardView, DailyView, WeeklyView, cards
│   ├── Workouts/         # WorkoutListView, WorkoutLogView, WorkoutDetailView
│   ├── Chat/             # ChatView, ChatViewModel
│   ├── BodyMap/          # BodyMapView, BodyMapViewModel, PartDetailSheet, BodyPartRegistry
│   └── Vitality/         # VitalityAgeView, breakdown
├── DesignSystem/         # Colors, Typography, reusable components
├── Resources/
└── Tests/
```

Keep one primary type per file. Views stay small; extract subviews when a body exceeds ~60 lines.

## Screens and Behavior

### Dashboard (root, TabView)
Tabs: **Dashboard**, **Workouts**, **Chat**, **Vitality**.

- Segmented control at top: **Daily | Weekly**.
- **Daily**: cards for Steps (with goal ring), Heart Rate (resting + latest), Sleep (last night, hours + stage bar), Calories (active/resting burned).
- **Weekly**: 7-day bar/line charts for each metric, plus week-over-week change (%) and averages.
- Pull to refresh. Show skeleton/placeholder states while loading.
- Tapping a card opens a detail screen with a larger chart.

### Workouts (sub-screen)
- List of workouts (type, duration, calories, avg heart rate, date), newest first.
- "Add workout" sheet: type, duration, intensity, optional notes. Save to SwiftData.
- Also import HealthKit workouts and merge with manual ones (de-duplicate by start time + type).
- Weekly workout summary at top (count, total minutes, total calories).

### Chatbot
- Simple chat UI (message bubbles, input bar, typing indicator).
- Context given to the model: a compact summary of today's and this week's stats (no raw sample dumps).
- Put the model behind a `ChatService` protocol so the provider can be swapped. Provide a `MockChatService` for previews and tests.
- Never put API keys in source. Read from a local `Secrets.xcconfig` that is git-ignored, and document setup in the README.
- System prompt rules: general wellness info only, not medical advice or diagnosis; suggest seeing a clinician for concerning symptoms; do not invent data the user has not provided.

### Vitality Age (ego stat)
An original composite score, inspired by the idea of a "body age" metric but with our own formula and branding. **Do not use the WHOOP name, logo, colors, or claim to replicate WHOOP's algorithm.** Call it "Vitality Age".

- Input: rolling 7 to 30 day averages of resting heart rate, sleep duration and consistency, daily steps, active calories/workout minutes. HRV if available.
- Output: a "Vitality Age" in years, shown next to chronological age (user enters age or reads from HealthKit date of birth), plus the delta ("2.4 years younger").
- Implementation: the score is decided by the LLM from the Health JSON snapshot (see "Apple Health → JSON → LLM Scoring Pipeline" below). `VitalityAgeCalculator` is a pure Swift struct kept as the deterministic fallback and as a sanity check on the LLM's output. Each metric is scored 0 to 1 against age-adjusted reference ranges, weighted, then mapped to an age offset clamped to a sensible range (for example -10 to +10 years).
- Fallback weights and ranges live in one `VitalityConfig` constant so they are easy to tune. Document the formula in code comments.
- Needs a minimum number of days of data; otherwise show "Collecting data (X/7 days)" instead of a number.
- Always show a short disclaimer that this is an estimate for motivation, not a medical measurement.
- Breakdown view shows which metrics help or hurt the score.

## Body Map (wear and tear tracker)

A 3D body the user can rotate and tap. Each body part is color coded by status, similar in spirit to the wear-and-tear body views in sports games. Do not use any game's name, art, or assets.

### Status model
| Status | Color | Meaning | How it is set |
|---|---|---|---|
| `healthy` | none / neutral gray | No issues | default |
| `worked` | yellow (light) | Trained recently | auto, from logged and HealthKit workouts |
| `sore` | yellow (strong) | Sore or fatigued | user-set, or auto-escalated after heavy training |
| `injured` | red | Injury or pain | **user-set only**, never inferred |

- Red is never set automatically. Only the user can mark a part injured.
- Yellow intensity (0.0 to 1.0) fades over time: `worked` decays over about 48 to 72 hours unless retrained; `sore` stays until the user clears it or it expires after a user-chosen number of days.
- Show a legend (red = injured, yellow = sore / worked) and make color distinguishable without color alone (add an icon or pattern badge on the selected part and in the list view).

### Interaction
- Rotate with drag, pinch to zoom, double tap to reset the view. Front/back quick toggle button.
- Tap a part: highlight it, show a bottom sheet `PartDetailSheet` with: part name, current status, a segmented control (Healthy | Sore | Injured), severity slider 1 to 5, optional note, date started, and recent workouts that hit this part.
- When the part is **injured (red)**, `PartDetailSheet` shows a prominent **How to heal** section driven by `HealingRecommendations` (part-specific wellness tips: rest, gentle mobility, load management, when to seek care). Tips are general wellness guidance only — never diagnosis or treatment. Tapping a red region is the primary path into these recommendations.
- Selecting a part with no status change should do nothing to saved data.
- Also provide an accessible list view (VoiceOver users cannot rely on the 3D scene): a list of all body parts with status and the same detail sheet.
- Swipe or toggle between Daily and Weekly view: Weekly shows a heat map of cumulative load per part over 7 days.

### Body parts (regions)
Use a fixed registry in `BodyPartRegistry` (an enum `BodyPart: String, CaseIterable, Codable`). Entity names in the 3D file must match the enum raw values exactly.

`head`, `neck`, `leftShoulder`, `rightShoulder`, `chest`, `upperBack`, `lowerBack`, `abs`, `leftBicep`, `rightBicep`, `leftTricep`, `rightTricep`, `leftForearm`, `rightForearm`, `leftHand`, `rightHand`, `glutes`, `leftHip`, `rightHip`, `leftQuad`, `rightQuad`, `leftHamstring`, `rightHamstring`, `leftKnee`, `rightKnee`, `leftCalf`, `rightCalf`, `leftAnkle`, `rightAnkle`, `leftFoot`, `rightFoot`

Keep it to these regions for v1. Do not add finer muscle groups without asking.

### 3D implementation
- Use RealityKit with `RealityView`. Load a single `.usdz` body model (`Resources/Models/body.usdz`) whose child entities are one mesh per body part, named with the `BodyPart` raw values.
- Add `CollisionComponent` (generated from each mesh) and `InputTargetComponent` to each part. Handle taps with `SpatialTapGesture().targetedToAnyEntity()` and map the tapped entity name to a `BodyPart`.
- Color via a per-part `ModelComponent` material update (`SimpleMaterial` or `UnlitMaterial`), not by swapping meshes. Blend base skin tone toward yellow or red by severity/intensity. Animate color changes (about 0.25 s).
- Add a subtle pulse on injured parts. Respect "Reduce Motion" (no pulse when enabled).
- Do not do orbit math by hand: rotate the root entity around Y with a drag gesture, clamp pitch, and keep the model centered.
- **Model asset:** use a neutral, gender-neutral low-poly body that the team made or that is CC0 / properly licensed. Record the source and license in `Resources/Models/LICENSE.md`. Never use a ripped or unlicensed game model. Keep the file under about 5 MB and under 50k triangles for smooth performance.
- **Fallback:** if the 3D asset is missing or fails to load, show a 2D front/back SVG-style body (`BodyMap2DView`) with the same tap regions and statuses. Build the 2D view first if the 3D asset is not ready; both share `BodyMapViewModel`.

### Data
- SwiftData model `BodyPartStatus`: `part: BodyPart`, `status: BodyStatus`, `severity: Int (1...5)`, `note: String?`, `startedAt: Date`, `updatedAt: Date`, `source: manual | autoWorkout`.
- A `WorkoutLoadMapper` maps workout types and logged exercises to body parts (for example running → quads, hamstrings, calves, glutes; push-ups → chest, shoulders, triceps). Keep the mapping in one table in `WorkoutLoadMapper.swift` so it is easy to edit.
- When a workout is saved or imported, `WorkoutLoadMapper` bumps the yellow `worked` intensity for the mapped parts, scaled by duration and average heart rate.
- The Add Workout sheet gets an optional "Muscles worked" picker, prefilled from the workout type.
- All body status data stays on device in SwiftData. It is health data; do not log it in release builds.

### Safety and copy
- Never diagnose. Use wording like "marked as injured by you". If a part stays red for 7 or more days, or severity is 4 to 5, show a gentle note suggesting the user see a clinician or physical therapist.
- Show a short disclaimer on the Body Map screen: tracking aid only, not medical advice.
- The chatbot may read body status for context but must not tell the user to train through a red part.

### Feeds the LLM scoring
Body status is included in the `HealthSnapshot` (see `body_status` in the schema) so the LLM can factor soreness and injuries into Readiness and Effort recommendations and explain them.

## HealthKit Rules

- Request read access only for: stepCount, heartRate, restingHeartRate, heartRateVariabilitySDNN, sleepAnalysis, activeEnergyBurned, basalEnergyBurned, workouts, dateOfBirth (optional).
- Add `NSHealthShareUsageDescription` to Info.plist with a clear, honest explanation. Enable the HealthKit capability.
- Wrap HealthKit in `HealthKitManager` behind a protocol (`HealthDataProviding`) so views and view models never import HealthKit directly.
- Use `HKStatisticsCollectionQuery` for daily/weekly aggregates; `HKSampleQuery` for sleep and workouts.
- Handle: authorization denied, no data, and simulator (HealthKit has limited data there). Provide a `MockHealthDataProvider` with realistic sample data and use it in previews and UI tests.
- Health data stays on device. Do not log raw health values to the console in release builds.

## Apple Health → JSON → LLM Scoring Pipeline

Instead of hard-coding every score formula, the app reads Apple Health through HealthKit, condenses it into a compact JSON snapshot, and sends that JSON to an LLM. The LLM decides how the WHOOP-style metrics are computed and explained: Vitality Age, Readiness (recovery-like), Effort (strain-like), and Sleep Score. Use these original names in the UI, never WHOOP's names or branding.

### Data flow
1. `HealthKitManager` fetches aggregates and samples (see HealthKit Rules).
2. `HealthSnapshotBuilder` converts them into a `HealthSnapshot` struct (Codable) and encodes it to JSON.
3. `ScoringService` (protocol, with `LLMScoringService` and `MockScoringService`) sends the snapshot plus the scoring system prompt to the LLM.
4. The LLM returns a `ScoreResult` as strict JSON.
5. The app validates it, falls back to `VitalityAgeCalculator` if invalid, caches it in SwiftData, and renders it.

Files: `Core/Scoring/HealthSnapshot.swift`, `HealthSnapshotBuilder.swift`, `ScoringService.swift`, `ScoreResult.swift`, `ScoringPrompt.swift`.

### Input JSON schema (`schema_version: 1`)
Send summaries, never raw sample streams. Target under ~4 KB. Omit fields that are unavailable (use `null`, never fake values).

```json
{
  "schema_version": 1,
  "generated_at": "2026-10-24T10:30:00-04:00",
  "window_days": 30,
  "profile": {
    "age_years": 22,
    "biological_sex": "male",
    "height_cm": 178,
    "weight_kg": 76
  },
  "today": {
    "steps": 6120,
    "active_kcal": 410,
    "basal_kcal": 1780,
    "resting_hr_bpm": 58,
    "latest_hr_bpm": 72,
    "hrv_sdnn_ms": 64,
    "sleep": {
      "total_hours": 7.2,
      "in_bed_hours": 7.9,
      "deep_hours": 1.1,
      "rem_hours": 1.6,
      "core_hours": 4.5,
      "awake_hours": 0.5,
      "bedtime": "23:40",
      "wake_time": "07:35"
    },
    "workouts": [
      { "type": "running", "minutes": 35, "kcal": 380, "avg_hr_bpm": 152, "max_hr_bpm": 176 }
    ]
  },
  "daily_history": [
    {
      "date": "2026-10-23",
      "steps": 9300,
      "active_kcal": 520,
      "resting_hr_bpm": 59,
      "hrv_sdnn_ms": 61,
      "sleep_hours": 6.8,
      "workout_minutes": 45
    }
  ],
  "body_status": [
    { "part": "leftQuad", "status": "sore", "severity": 3, "days_since_start": 1 },
    { "part": "rightKnee", "status": "injured", "severity": 2, "days_since_start": 6 },
    { "part": "chest", "status": "worked", "intensity": 0.7, "hours_since_last_load": 20 }
  ],
  "baselines": {
    "resting_hr_bpm_30d_avg": 59,
    "hrv_sdnn_ms_30d_avg": 62,
    "sleep_hours_30d_avg": 7.0,
    "steps_30d_avg": 8400,
    "sleep_consistency_stddev_min": 42
  },
  "data_quality": {
    "days_with_data": 27,
    "missing_metrics": ["hrv_sdnn_ms"]
  }
}
```

Rules for the snapshot:
- `daily_history` holds at most 30 entries, one per day, oldest first.
- Never include name, email, device IDs, location, or exact timestamps of individual samples.
- Round values (steps to integer, hours to 1 decimal, HR to integer) to keep the payload small.
- Compute baselines on device, not in the LLM.
- `body_status` lists only non-healthy parts. Omit free-text notes; they may contain personal details.

### Output JSON schema (`ScoreResult`)
The LLM must return only valid JSON matching this shape, no prose, no markdown fences:

```json
{
  "schema_version": 1,
  "vitality_age": {
    "years": 20.6,
    "delta_vs_chronological": -1.4,
    "confidence": "medium",
    "drivers": [
      { "metric": "resting_hr", "effect_years": -0.8, "note": "Resting HR is below your 30-day norm." },
      { "metric": "sleep_consistency", "effect_years": 0.5, "note": "Bedtime varies by about 40 minutes." }
    ]
  },
  "readiness": { "score": 78, "label": "good", "summary": "HRV and resting HR are near baseline." },
  "effort": { "score": 11.4, "scale_max": 21, "summary": "Moderate day from a 35 minute run." },
  "sleep_score": { "score": 84, "summary": "Solid duration, slightly low deep sleep." },
  "method": "Short plain-English description of how these were derived from the input.",
  "insufficient_data": false,
  "disclaimer": "Estimate for motivation only, not medical advice."
}
```

### Scoring system prompt (put in `ScoringPrompt.swift`)
The prompt must tell the model to:
- Act as a wellness analytics engine, not a doctor. No diagnoses or treatment advice.
- Judge each metric relative to the user's own `baselines` first, then to age and sex appropriate population norms.
- Use HRV and resting HR trends for Readiness; training load (workout minutes, intensity from HR) for Effort; duration, stages, and consistency for Sleep Score; a combination of all long-term averages for Vitality Age.
- Treat `body_status` as context: injured parts (red) and high-severity soreness lower Readiness and should be named in `drivers`; never recommend training through an injured part; `worked` parts raise Effort context but are not a problem on their own.
- Return `insufficient_data: true` and null scores when `days_with_data` is below 7, instead of guessing.
- Keep `vitality_age.delta_vs_chronological` within -10 to +10 years.
- Explain its method briefly in `method` and list the top 2 to 4 `drivers`.
- Output strict JSON only, matching the schema, and never invent input values.
- Use temperature 0 to 0.2 for consistent scores. Pin the model name in config.

### Validation and safety (required)
- Decode with `JSONDecoder` into `ScoreResult`. On any decode failure, retry once, then use `VitalityAgeCalculator` and show a small "estimated locally" label.
- Clamp scores: Readiness and Sleep Score 0 to 100, Effort 0 to 21, Vitality Age delta -10 to +10.
- Reject results that contradict the data (for example a "great" Readiness with no data). Log a non-sensitive reason.
- Cache one `ScoreResult` per snapshot hash per day in SwiftData; do not re-call the LLM on every screen open. Refresh on pull-to-refresh or once HealthKit reports new data.
- Chatbot reuses the latest `HealthSnapshot` and `ScoreResult` as context so its answers match the dashboard.

### Privacy and security
- Show a one-time consent screen explaining that a summary of health data is sent to an AI provider, with a toggle to disable it. If disabled, use only the local fallback calculator.
- Send only the snapshot JSON. No raw samples, no identifiers.
- Prefer routing LLM calls through a thin backend proxy so the API key is not embedded in the app. For a hackathon demo, a git-ignored `Secrets.xcconfig` key is acceptable; document it in the README.
- Do not log full snapshots or results in release builds.
- Include a "View data sent" debug screen in debug builds that shows the exact JSON payload.

### Testing the Body Map
- `WorkoutLoadMapper`: each workout type maps to the expected parts; intensity scales with duration and heart rate; intensity decays over time.
- Status rules: red is never set by auto logic; `worked` never overwrites `injured`; clearing a part resets it to healthy.
- Tap handling: entity name to `BodyPart` mapping covers every enum case (test that the registry and the model entity names match).
- Snapshot includes only non-healthy parts and omits notes.

### Testing the pipeline
- Snapshot builder: given mock HealthKit data, assert exact JSON output, rounding, field omission, and the 30-day cap.
- Decoder: test valid output, malformed JSON, extra fields, missing fields, and out-of-range values.
- Use `MockScoringService` with canned JSON fixtures in `Tests/Fixtures/` (good week, bad week, sparse data).
- Fallback: verify the app still renders all scores when the LLM call fails or times out.

## Design Guidelines

- Simple and clean: generous spacing, rounded cards, one accent color per metric (steps green, heart red, sleep indigo, calories orange).
- Support Dark Mode and Dynamic Type. Use system fonts and SF Symbols.
- Accessibility: labels on every chart and card, minimum 44pt tap targets, do not rely on color alone.
- Put reusable pieces (`MetricCard`, `RingView`, `SectionHeader`) in `DesignSystem/`.
- Every screen gets a `#Preview` using mock data.

## Coding Conventions

- Follow the Swift API Design Guidelines. Types `UpperCamelCase`, everything else `lowerCamelCase`.
- Prefer `struct` and value types; use `final class` only for `@Observable` view models and services.
- No force unwraps (`!`) or `try!` outside tests. Handle errors and surface user-friendly messages.
- No magic numbers: put thresholds, goals, and weights in named constants.
- Keep business logic out of views. Views render state; view models hold logic.
- Add `///` doc comments on public types and any non-obvious calculation.
- Prefer small, focused commits and changes. Do not refactor unrelated code.

## Testing

- Unit test `VitalityAgeCalculator` thoroughly: boundary values, missing metrics, insufficient data, clamping, monotonic behavior (better stats never raise the age).
- Unit test weekly aggregation, week-over-week math, and workout de-duplication.
- Use the mock providers for view model tests. Use Swift Testing (`import Testing`) or XCTest, matching what is already in the project.
- Run tests before declaring a task done.

## Required Deliverables: README, Requirements, Run Steps

When an AI assistant builds or substantially changes this project, it **must** create and keep up to date these files at the repo root. The project is not done until a stranger can clone the repo and run it by following the README alone. Do not skip this, even if not asked again.

### 1. `README.md`
Must contain, in this order:
1. **Title and one-line description**
2. **Features**: Daily/Weekly dashboard, steps, heart rate, sleep, calories, workouts, Body Map, chatbot, Vitality Age and other scores
3. **Screenshots or a demo GIF** (placeholder section if not yet captured)
4. **Requirements**: the list below
5. **Setup and Run (step by step)**: see the template below
6. **Using mock data vs real Apple Health data**
7. **How the AI scoring works**: short explanation of Health JSON → LLM → `ScoreResult`, and the local fallback
8. **Project structure**: short tree
9. **Running tests**
10. **Privacy**: what data is read, what is sent to the AI provider, and how to turn it off
11. **Troubleshooting**
12. **Disclaimer**: wellness tool, not medical advice
13. **License and asset credits** (including the 3D model source and license)

### 2. `REQUIREMENTS.md`
List everything needed to run the project, with versions:
- macOS version able to run the current stable Xcode
- Xcode (latest stable; must include the iOS 18 or newer SDK)
- iOS Simulator runtime, iOS 18 or newer (or a physical iPhone on iOS 18 or newer)
- Apple ID signed into Xcode (free account is enough to run on your own device; HealthKit needs a real device or simulator, see below)
- An LLM provider API key (optional: the app falls back to the local calculator without one)
- Optional: Homebrew and SwiftLint
- Swift Package dependencies, if any (name, version, purpose). Currently none.
- A note on what works in the simulator vs on a real device (HealthKit data is limited in the simulator; use mock data or add samples in the Health app)

Also add a `Secrets.example.xcconfig` (committed) that shows the required keys with placeholder values. The real `Secrets.xcconfig` stays in `.gitignore`.

### 3. Step-by-step run instructions (macOS only)
The README "Setup and Run" section must follow this template and be kept accurate to the actual project (correct project name, scheme, and file names):

```markdown
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
1. Click the project in the left sidebar, then the HealthTracker target.
2. Open Signing & Capabilities.
3. Select your Team and keep "Automatically manage signing" on.
4. Confirm the HealthKit capability is listed. Add it with "+ Capability" if not.

### 6. Run on the simulator
1. Pick an iPhone simulator (iOS 18+) in the top toolbar.
2. Press Cmd+R.
3. Tap "Allow" on the Health permission sheet, or choose Mock Data in Settings.

### 7. (Optional) Run on a real iPhone for real health data
1. Connect your iPhone and trust the computer.
2. Enable Developer Mode on the phone (Settings → Privacy & Security → Developer Mode).
3. Select your phone in the toolbar and press Cmd+R.
4. Allow Health access when prompted.

### 8. Run the tests
```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 15'
```
(Or press Cmd+U in Xcode. If that simulator name does not exist, run `xcrun simctl list devices available` and use one that does.)
```

Rules for these instructions:
- macOS commands only. No Windows or Linux variants.
- Every command must be in a fenced `bash` block and must actually work as written.
- Each step is numbered and has one clear action. Do not assume prior Xcode knowledge.
- Do not tell the reader to "configure X" without saying where to click.
- Include the expected result after key steps (for example "You should see the Dashboard with Daily and Weekly tabs").

### Mock data switch
To make the app runnable by anyone without Health data or an API key:
- Add a launch argument `-useMockData` and a Settings toggle that swaps in `MockHealthDataProvider` and `MockScoringService`.
- The README must explain how to enable it (Xcode: Product → Scheme → Edit Scheme → Run → Arguments → add `-useMockData`).
- Mock mode must populate all screens: Daily, Weekly, Workouts, Body Map (a couple of yellow and one red part), Vitality Age, and Chat.

### Keep docs in sync
- If a command, scheme name, setting, or dependency changes, update README and REQUIREMENTS in the same change.
- Before finishing, re-read the README top to bottom and verify each step against the project.

## Commands (macOS)

```bash
# Open the project
open HealthTracker.xcodeproj

# Build for simulator
xcodebuild -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 15'

# List available simulators
xcrun simctl list devices available

# Lint (if SwiftLint is installed)
brew install swiftlint
swiftlint
```

## Workflow for the AI Assistant

1. Read the relevant files before editing. Do not guess at existing APIs.
2. For anything bigger than a small fix, state a short plan first, then implement in small steps.
3. Build after each meaningful change and fix compiler errors and warnings before moving on.
4. Do not edit `.pbxproj` by hand unless unavoidable. If new files must be added to the target, tell the user.
5. Do not add dependencies, change the deployment target, or change entitlements without asking.
6. Never commit secrets, API keys, or real health data.
7. When requirements are ambiguous, ask one concise question rather than assuming.
8. Always create or update `README.md`, `REQUIREMENTS.md`, and the step-by-step run instructions (see "Required Deliverables"). Do this without being asked.

## Suggested Build Order

1. Project setup, folder structure, design system basics
2. Mock data layer + models + dashboard UI (Daily, then Weekly)
3. HealthKit integration behind the provider protocol
4. Workouts screen with SwiftData
4b. Body Map: `BodyPart` enum + `BodyPartStatus` model + 2D body map first, then the 3D RealityKit view, then `WorkoutLoadMapper` auto-yellow
5. `HealthSnapshotBuilder` + JSON schema + `MockScoringService`, then `LLMScoringService` with validation and fallback `VitalityAgeCalculator`, plus tests and UI
6. Chatbot with mock service, then real provider (reusing the snapshot and score as context)
7. Polish: empty/error states, accessibility, app icon
8. Write `README.md`, `REQUIREMENTS.md`, and `Secrets.example.xcconfig`, then follow the README from a clean clone to verify it works

## Definition of Done

- Builds with zero warnings on the latest stable Xcode
- Works with both mock data and real HealthKit data
- Previews render for each screen
- Unit tests pass
- Accessibility labels and Dark Mode verified
- No secrets or personal data in the repo
- `README.md` and `REQUIREMENTS.md` exist, are accurate, and include step-by-step macOS run instructions
- `Secrets.example.xcconfig` is committed and `Secrets.xcconfig` is git-ignored
- App runs end to end in mock mode with no API key and no Health data
