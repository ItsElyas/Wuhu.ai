# Kiro CLI guidance session — 2026-10-24

Informational architecture guidance for upcoming Wuhu work (Workout Hub, onboarding, prescriptions, PBT, privacy). No code was generated in this session.

## CLI identity

| Field | Value |
|--------|--------|
| Binary | `/Users/itselyas/.local/bin/kiro-cli` (`kiro` not on PATH) |
| Version | **kiro-cli 2.34.0** |
| Engine | KAS (Kiro Agent Server) **0.66.62**, agent engine **v3** |
| Auth | Logged in (`kiro-cli whoami`) |
| Session ID | `sess_6013627c-5eaa-4fdb-a712-fe1dd83ee6a3` |

## Command (copy-paste safe)

Run from repo root `/Users/itselyas/Wuhu/Wuhu`:

```bash
cd /Users/itselyas/Wuhu/Wuhu

PROMPT='You are advising on the Wuhu iOS 18 SwiftUI app (MVVM with @Observable). No code generation—informational architecture guidance only.

Context:
- Workout Hub: HubSessionService writes HubSession/HubExercise/HubSetLog to SwiftData; ActiveWorkoutView + WorkoutHubView; HubRegimenBuilder builds regimens.
- Core/Wuhu: WorkoutDatabaseEngine + workout_prescriptions.json via WorkoutPrescriptionLoader; PlayerProfileStore (UserDefaults stub for AthleteOnboardingEngine.PlayerProfile); WSLAutoEvaluator + WSLScaleModels for six-tier WSL score on Home.
- Chat uses Gemini via ChatOrchestrator + WuhuChatContext (not raw HealthKit dumps).
- Spec: .kiro/specs/wuhu-core/requirements.md (R2 port milestone).

Answer concisely with actionable recommendations for each:

1) SwiftUI + @Observable: best pattern to wire Workout Hub live session engine (set completion, rest timer, Live Activity) to HubSessionService/SwiftData without bloating views—where should state live vs HubSessionService?

2) Spec-driven next steps for full AthleteOnboardingEngine UI (sex question at start, WSL battery visualization) aligned with existing PlayerProfileStore stub and Home WSL display.

3) Connect workout_prescriptions.json → WorkoutDatabaseEngine → "Today'\''s Workout" pill on Workout Hub without duplicating R2 monolith logic—single source of truth boundaries.

4) Property-based testing targets per hackathon steering: WSL composite score clamping invariants; WorkoutDatabaseEngine progressive overload rules—list concrete properties to test.

5) Privacy: HealthKit + Hub SwiftData logs stay on device; only WuhuChatContext/snapshot summaries go to Gemini—validate this split and name any leaks to avoid.

Keep answers implementation-oriented for a small team.'

/Users/itselyas/.local/bin/kiro-cli chat \
  --no-interactive \
  --trust-workspace \
  --mode spec \
  --output-format stream-json \
  "$PROMPT" \
  2>&1 | tee docs/kiro-cli-wuhu-session-2026-10-24.jsonl
```

**Note:** `--mode spec` was passed; Kiro still read the workspace (HubSessionService, WuhuChatContext, WorkoutHubView, Live Activity) via tools before answering.

## Usage / token stats

| Metric | Value |
|--------|--------|
| Turn credits (`promptTurnSummaries`) | **~1.49 credits** |
| Elapsed | **~85 s** |
| Tools used | `read_file`, `file_search`, `list_directory` |
| Context breakdown (initial) | `yourPrompts` ~4293 tokens; builtin tools ~6384 tokens in window |
| Final assistant text | ~12.9 KB (~3k+ tokens estimated) |
| `--max-tokens` | **Not available** on `kiro-cli chat` |

**~1000-token target:** Not precisely controllable. One non-interactive turn consumed **>1000 tokens** of model output plus tool reads; credit meter **~1.49** is the billed proxy. For tighter budgets, use shorter prompts and `--output-format text` without codebase tool use (supervised / no file reads).

## Full transcript

- **Stream JSON (complete CLI stdout):** [kiro-cli-wuhu-session-2026-10-24.jsonl](./kiro-cli-wuhu-session-2026-10-24.jsonl)
- **Final synthesized answer:** below (from `runFinished.finalText`).

---

Let me look at the actual code before advising, so recommendations match how your services and models are already structured.Let me check HubSessionService and the WuhuChatContext to ground answers 1, 3, and 5.I have enough grounding. Let me check the live activity controller and WorkoutHubView briefly to anchor answers 1 and 3 precisely.I now have a solid picture of the actual architecture. Here's my grounded guidance.

## 1) Wiring the live session engine with @Observable + SwiftData

Your current design is already the right spine — keep it. `HubSession`/`HubExercise`/`HubSetLog` are `@Model`, `ActiveWorkoutView` binds directly with `@Bindable var session`, edits save immediately through `HubSessionService`, and the view drives the Live Activity via `.onChange(of: totalsText)`. The principle to hold: **SwiftData is the single source of persistent truth; `HubSessionService` owns all writes; the view owns only ephemeral UI state.**

Where state should live:

- **Persistent workout state** (sets, reps, weights, completion, segments) → SwiftData models, mutated only through `HubSessionService`. Do not mirror these into a separate `@Observable` session engine; that creates two sources of truth you'll have to reconcile. Set completion is just `set.isCompleted = true` + `context.save()` — add a `HubSessionService.complete(_ set:in:)` so completion and the resulting Live Activity update flow through the service, not ad-hoc in the view.
- **Rest timer** → this is the one piece that is genuinely *not* persistent domain data and doesn't belong in a `@Model`. Put it in a small `@MainActor @Observable RestTimerModel` owned by `ActiveWorkoutView` as `@State`. It holds `endsAt: Date`, derives remaining time, and fires a local notification + `WorkoutLiveActivityController.update` on expiry. If you want it to survive the app being backgrounded, persist only `endsAt` (e.g. a field on `HubSession` like `restEndsAt: Date?`) and let the timer model read it on appear — store the deadline, not a ticking countdown.
- **Live Activity** → keep it as the side-effect layer it already is. `WorkoutLiveActivityController` is correctly stateless and derives everything from the `HubSession`. One improvement: the view currently calls `update` on a `totalsText` change; route set-completion and rest-timer events through the service so the service calls `update`, keeping the view from orchestrating.

Concretely, to avoid view bloat: move the set-completion/add-set/rest-start logic that's inline in `ActiveWorkoutView` / `LiftExerciseCard` into `HubSessionService` methods that each do mutate → save → `WorkoutLiveActivityController.update`. The view then only toggles bindings and reads derived computed properties (`completedSetCount`, `totalVolumeLbs`) that already live on the model. No ViewModel layer is needed here — `@Model` + `@Bindable` + a service enum is the idiomatic iOS 18 pattern and you're already on it.

## 2) Spec-driven next steps for full onboarding UI

The engine (`AthleteOnboardingEngine`) and persistence (`PlayerProfileStore`) are complete and already encode sex as a first-class `Gender` field that the WSL math branches on. What's missing is only the UI and the write path. Spec tasks, in dependency order:

1. **Onboarding flow shell** — a `@Observable OnboardingDraft` holding the in-progress answers (name, age, height, weight, activity, sport, and the raw WSL inputs). This is ephemeral UI state, not persisted until the end. Sex asked *first* is correct and matters: every WSL branch (`evaluateCompositeWSL`) and the running/powerlifting standards are sex-calibrated, so collect `Gender` before any metric screen so downstream screens can show sex-specific reference bands.
2. **Sport + metric capture screens** — running asks 5K time (+ optional RHR); powerlifting asks SBD total (+ optional squat/bench). Map these directly to `primaryVal` / `subMetricA` / `subMetricB`. Surface the "optional inputs raise confidence" relationship in the UI so users understand provisional vs firm.
3. **Finish → persist** — call `makeProfile(...)` (which validates and throws the typed `OnboardingError`s), attach the `WSLCompositeEvaluation` from `evaluateCompositeWSL`, then `PlayerProfileStore.save`. Surface the thrown errors inline per field.
4. **WSL battery visualization** — render `WSLCompositeEvaluation.subMetrics` as a bar/radar battery: each `SubMetric` has `name`, `score` (1–6), `weight`, `notes`, and `rawValue`/`unit`. Show the composite as the six-tier ladder (`WSLScaleRank.title`) with the `confidencePercentage` and the `isProvisional` "estimated" badge. This reuses `WSLScorePresentation.from(evaluation:)` that Home already uses.
5. **Reconcile Home's two paths** — today Home can show an *estimated* score from `WSLAutoEvaluator` (resolves profile → Health → settings → population) while `PlayerProfileStore.wslPresentation()` returns the *stored* profile eval. Spec a rule: completed onboarding profile is authoritative; `WSLAutoEvaluator` only fills in when `profile == nil` or a profile field is absent. Make the "estimated" badge consistent across the onboarding battery and the Home card so the same number never appears with two confidences.

Note one existing subtlety to document in the spec: `AutoEvaluator` averages male+female scales when sex is unknown. Once onboarding makes sex mandatory-first, that averaging path only applies to the pre-onboarding Home estimate — keep it, but the onboarding result should never be sex-averaged.

## 3) prescriptions.json → engine → "Today's Workout" pill (single source of truth)

The pipeline already exists and the boundaries are clean — the task is to *reuse* it, not re-derive R2 logic in the view. The flow:

`workout_prescriptions.json` → `WorkoutPrescriptionLoader.loadFromBundle()` (falls back to `Repository.buildWeeklyExerciseBank()` if the bundle file is missing/empty) → `WorkoutDatabaseEngine.exerciseBank`.

For "Today's Workout":

- **Selection boundary** — `WorkoutDatabaseEngine` is the only thing that knows the bank. Add one method there: `prescription(for sport:on date:)` that filters `exerciseBank` by `sport` and `DayOfWeek.from(date:)` (that helper already exists on the enum). Pass the user's sport from `PlayerProfileStore.profile?.selectedSport` (the `HubWorkoutKind.sport` mapping already bridges kind↔sport). Don't let the view filter the bank itself.
- **Overload boundary** — if the pill shows prescribed load, go through `generateOverloadPrescription(for:weekNumber:wslScaleRank:)`. That's the one place progression/deload/WSL-scaling lives; the view must not recompute weights. Feed it `wslScaleRank` from the stored evaluation's `rank`.
- **Display boundary** — `HubRegimenBuilder.regimen(from:kind:)` is the one translator from an `ExercisePrescription` to displayable/loggable items. The pill should show `Regimen.title`/`focus` from that, and "Start" hands the same `Regimen` to `HubSessionService.start`. This guarantees the pill preview and the started session are identical — no divergence.

So the only new surface is `WorkoutDatabaseEngine.prescription(for:on:)` plus a tiny view that renders a `Regimen` and a Start button. Everything downstream is already wired. The single source of truth: JSON is data, `WorkoutDatabaseEngine` owns selection + progression, `HubRegimenBuilder` owns presentation translation, `HubSessionService` owns the write. No R2 monolith logic gets duplicated because the view touches none of it.

## 4) Property-based testing targets

These are both pure/deterministic (`HubRegimenBuilder` is explicitly documented as such, and the WSL engine and progression rules are pure functions), so they're ideal for property tests with randomized inputs (Swift Testing with generated values, or swift-check-style loops over random seeds).

**WSL composite clamping / invariants** (`evaluateCompositeWSL`, `WSLScaleRank.from`):
- For any valid inputs, `compositeScore` stays within the 1.0–6.0 band (each `SubMetric.score` is 1–6 and normalized weights sum to 1, so the weighted sum can never leave [1,6]). Assert it.
- Normalized `subMetric` weights always sum to ~1.0 (within epsilon) whenever any sub-metric exists.
- `rank == WSLScaleRank.from(compositeScore:)` — the returned rank is always consistent with the score, and the `from` thresholds are total and monotonic: a higher score never maps to a lower rank.
- Monotonicity of performance → score: for powerlifting, increasing `total` with all else fixed never decreases `compositeScore`; for running, decreasing 5K time never decreases it. (Guards against a mis-ordered threshold band.)
- Confidence invariants: `confidencePercentage ∈ {40,70,100}` by optional-input count for the engine, and `isProvisional == (confidence < 70)`.
- `WSLAutoEvaluator` clamp: `clampedConfidence ∈ [15,100]` for any input, and `estimatedFields` is non-empty whenever confidence < 100.

**Progressive overload rules** (`generateOverloadPrescription`):
- Weight-jump cap: for any tier with `maxWeightJumpLbs > 0`, `finalWeight - adjustedBaseline ≤ maxWeightJumpLbs` always holds.
- Non-negative progression: `finalWeight ≥ adjustedBaseline` on progression, and on a deload week `prescribedWeightLbs < adjustedBaseline` and `prescribedSets ≥ 1` (the `max(1, …)` floor).
- Recovery tiers: for `activeRecovery`/`completeRest`, `prescribedWeightLbs == 0` for *all* week numbers and WSL ranks.
- Cadence honoring: for a tier with `cadenceWeeks == 2`, load only steps on weeks where `(week-1) % 2 == 0` — i.e. two consecutive non-deload weeks never both increase load. (This is the exact bug the inline comment calls out.)
- Deload periodicity: a deload fires iff `week % deloadFrequencyWeeks == 0`, and never coincides with a load increase.
- WSL scaling monotonic: higher `wslScaleRank` yields `adjustedBaseline` that is ≥ the lower rank's, across all ranks (0.65 → 1.35 ladder).
- RPE gating: given a logged set, RPE ≥ 9.0 or `achievedReps < targetReps` always yields zero increase (hold), and RPE ≤ 7.5 with target met yields the max increase — never the reverse.

Also worth a property test on `classifyTier`: every running prescription classifies to `.enduranceAerobic`, and combined blocks classify by lead movement (the two misfires documented in the comments — "Ab Crunch" matching "run", seal-row ordering — make good explicit regression cases).

## 5) Privacy split — validation and leaks to avoid

The intended split holds and the code mostly enforces it: raw HealthKit and Hub SwiftData logs stay on device, and only compact summaries (`HealthSnapshot`, schema v1) plus the `WuhuChatContext` dossier go to Gemini. `HealthSnapshot` is already a deliberately reduced projection (aggregates and rounded metrics, not raw samples), which is the correct shape to send. Confirm these boundaries in the spec and watch for these specific leaks:

- **PII in the dossier.** `WuhuChatContext.systemPromptSection` sends `profile.name`, exact age, exact bodyweight, BMI, and biological sex to Gemini on every chat. Decide deliberately whether name needs to leave the device — it almost certainly doesn't help coaching. Prefer sending sex/age-band/weight rather than name + exact values, or gate name behind a setting.
- **Free-text leakage.** `HubSession.notes`, `HubExercise`/exercise names typed by the user, and `summary(session)` can contain anything a user types. If any of these feed chat context, they bypass the structured snapshot. Keep the chat context assembled only from the typed `HealthSnapshot`/dossier structs — never splice in raw model notes.
- **Snapshot scope creep.** `HealthSnapshot` currently excludes raw per-sample data by design. The leak risk is future fields: if someone adds `bedtime`/`wakeTime` (already present) plus precise timestamps, you start transmitting location-adjacent routine data. Keep the snapshot to aggregates and keep `SnapshotDataQuality.missingMetrics` as *metric names*, never values.
- **Diagnostics endpoints.** You have `GeminiChatDiagnostics` and `HealthDataDiagnostics` — make sure diagnostic/logging paths don't serialize the full snapshot or raw HealthKit into logs that leave the device (crash reporters, analytics). On-device logs are fine; exported ones are the risk.
- **Transport.** Confirm the Gemini client only sends the assembled context and user turns, with the key from `Secrets.xcconfig` (not committed). Nothing in `HealthKitManager` should have a network path — verify HealthKit data only ever reaches the network *after* passing through the `HealthSnapshot` reducer.

Net: the architecture is sound. The concrete action items are (a) trim name/exact PII from the chat dossier, (b) guarantee free-text notes/exercise names never enter chat context, and (c) assert in a test that the only outbound payload is `HealthSnapshot` + dossier — no raw `HubSetLog`/`WorkoutRecord`/HealthKit samples.
