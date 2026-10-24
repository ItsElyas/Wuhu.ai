# Kiro usage

## 2026-10-24 — Home dashboard spec

- Added `.kiro/specs/home-dashboard/` with requirements (UI spec sections 3–6), design (tokens, components, `HomeState`), and tasks (section 7 build order).
- The Home screen was then implemented from that spec: `NavigationStack` root, Ego Score, Wear & Tear mapping, and `HomeFixture.reference` for mock mode.
- Plus Jakarta Sans and final body art remain open tasks.

## 2026-10-24 — Weekly performance

- Added `.kiro/specs/weekly-performance/` from the running and powerlifting reference screens.
- Home Weekly Stats pushes that screen. The stub mode defaults to running. Debug builds can preview powerlifting.

## 2026-10-24 — Chat orchestrator (Gemini backend, built with Kiro CLI)

- Runtime chat is **not** a Kiro gateway: **`ChatOrchestrator`** (phases: reading health → thinking → updating) calls **`GeminiChatClient`** via **`ChatLLMProviding`**.
- Provider-neutral layer in `Core/Services/LLM/`: `ChatLLMTool` (`update_wear_and_tear`), `GeminiConfiguration` (`GEMINI_*` in `Secrets.xcconfig` → Info.plist), `MockChatLLMClient` for previews.
- **`ChatLocalFallback`** when AI consent is off or `GEMINI_API_KEY` is unset. Removed mistaken `Core/Services/Kiro/` OpenAI gateway client (keys had been labeled `KIRO_*` but were Gemini).

## 2026-10-24 — Kiro CLI informational session (Workout Hub / onboarding / PBT / privacy)

- **Tool:** `kiro-cli` **2.34.0** at `/Users/itselyas/.local/bin/kiro-cli` (not `kiro` on PATH). KAS **0.66.62** / agent engine **v3**.
- **Command:** `kiro-cli chat --no-interactive --trust-workspace --mode spec --output-format stream-json "<prompt>"` from repo root (see [docs/kiro-cli-guidance-2026-10-24.md](docs/kiro-cli-guidance-2026-10-24.md) for full copy-paste prompt).
- **Session:** `sess_6013627c-5eaa-4fdb-a712-fe1dd83ee6a3`; Kiro read `HubSessionService`, `WuhuChatContext`, `WorkoutHubView`, and Live Activity before answering.
- **Usage:** ~**1.49 credits**, ~85 s; initial context ~4293 prompt tokens in window; no `--max-tokens` flag. Full stdout: [docs/kiro-cli-wuhu-session-2026-10-24.jsonl](docs/kiro-cli-wuhu-session-2026-10-24.jsonl).
- **Questions:** (1) Workout Hub live session + SwiftData boundaries, (2) `AthleteOnboardingEngine` UI + WSL battery + `PlayerProfileStore`, (3) `workout_prescriptions.json` → Today's Workout pill without R2 duplication, (4) PBT for WSL clamping and progressive overload, (5) HealthKit/Hub on-device vs Gemini via `WuhuChatContext` only.
- **Summary of Kiro answers:**
  - Keep `@Model` + `@Bindable` + `HubSessionService` for persistence; add `RestTimerModel` for ephemeral rest; route Live Activity updates through service methods (`complete`, etc.).
  - Onboarding: `OnboardingDraft`, sex-first flow, `makeProfile` + `evaluateCompositeWSL`, WSL battery from `subMetrics`, authoritative profile vs `WSLAutoEvaluator` estimate.
  - Today's Workout: add `WorkoutDatabaseEngine.prescription(for:on:)`, overload via `generateOverloadPrescription`, display via `HubRegimenBuilder` → `HubSessionService.start`.
  - PBT: composite 1–6, rank monotonicity, confidence enums, overload caps/cadence/deload/RPE gates, `classifyTier` regressions.
  - Privacy: trim dossier PII (name); block Hub free-text in chat; test outbound payload is snapshot + dossier only.

## 10. 2026-10-24 — ~1000-token CLI Q&A marathon (hackathon evidence)

- **Goal:** Deliberately cap Kiro CLI usage at ~**1000 tokens** (prompt+answer), not a single ~14k-context / ~1.49-credit blast.
- **Tool:** `kiro-cli` **2.34.0** at `/Users/itselyas/.local/bin/kiro-cli`; **`--max-tokens` does not exist** on `chat`.
- **Method:** Nine separate `chat` turns with `--model claude-haiku-5.5 --effort low --trust-tools= --output-format stream-json`; **no `--trust-workspace`**. Cumulative **estimated** tokens (chars÷4 on prompt + `finalText`) stopped at **1013** after question 9; credits ~**0.138** total (`promptTurnSummaries` per turn).
- **Log:** [docs/kiro-cli-token-budget-2026-10-24.md](docs/kiro-cli-token-budget-2026-10-24.md) and [docs/kiro-cli-token-budget-2026-10-24.jsonl](docs/kiro-cli-token-budget-2026-10-24.jsonl).
- **Topics covered:** Hub rest timer boundaries, regimen/prescription order (Kiro declined without code), SwiftData `restEndsAt`, onboarding/profile conflict, WSL precedence, HubSetLog weekly aggregation, WearTear hook, chat context privacy trim, Live Activity ownership.
