# Kiro CLI ~1000-token budget marathon — 2026-10-24

Intentional short-turn informational Q&A on Wuhu (hackathon evidence). No code generation; no `--trust-workspace` (avoids repo-wide tool reads).

## CLI and limits

| Item | Value |
|------|--------|
| Binary | `/Users/itselyas/.local/bin/kiro-cli` **2.34.0** |
| Engine | KAS **0.66.62**, agent **v3** |
| Model | `claude-haiku-5.5` with `--effort low` |
| Flags checked | **`--max-tokens` not available** in `kiro-cli chat --help` |
| Per-turn billing in stream | `promptTurnSummaries[].usage` in **credits** (`kind: turn_completion`) |
| Context window breakdown | `contextUsage.breakdown` includes fixed ~6384 **tools** tokens per session (not counted toward this budget) |

### Token budget methodology

Kiro **does not emit** per-turn `inputTokens` / `outputTokens` / `total` in `stream-json`. For this marathon:

- **Budget metric:** estimated LLM tokens per turn = `ceil(len(user_prompt)/4) + ceil(len(finalText)/4)` from each `runFinished.finalText`.
- **Stop rule:** stop after a turn when **cumulative estimated tokens ≥ 950** (buffer under 1000).
- **Credits:** recorded per turn for cross-check (~**0.138 credits** total vs ~**1.49 credits** in the earlier single giant prompt session).

Raw JSONL: [kiro-cli-token-budget-2026-10-24.jsonl](kiro-cli-token-budget-2026-10-24.jsonl).

## Invocation template

From repo root:

```bash
cd /Users/itselyas/Wuhu/Wuhu

/Users/itselyas/.local/bin/kiro-cli chat \
  --no-interactive \
  --model claude-haiku-5.5 \
  --effort low \
  --trust-tools= \
  --output-format stream-json \
  "YOUR SHORT QUESTION. 2-4 bullets, max 80 words. No tools."
```

- **Do not** use `--trust-workspace` for budget runs (prior session read six files and spent ~1.49 credits).
- Prefer **new session per question** (`--resume` not used) to keep answers isolated.
- Parse usage: `grep turn_completion` or read final `runFinished` + `promptTurnSummaries` in the JSONL.

## Turn log

| Turn | Topic (short) | In (est.) | Out (est.) | Total (est.) | Cumulative | Credits | Kiro answer summary |
|------|---------------|-----------|------------|--------------|------------|---------|---------------------|
| 1 | HubSessionService vs VM rest timer | 40 | 92 | 132 | 132 | 0.078 | Service owns timer/end time; ViewModel observes and forwards UI intents. |
| 2 | HubRegimenBuilder + `prescription(for:on:)` order | 36 | 100 | 136 | 268 | 0.018 | Refused to guess without code; offered to trace if snippets pasted. |
| 3 | SwiftData `restEndsAt` migration | 25 | 92 | 117 | 385 | 0.005 | Optional `Date` + lightweight migration; VersionedSchema V2 if already versioned. |
| 4 | OnboardingDraft vs PlayerProfileStore | 24 | 117 | 141 | 526 | 0.006 | No tools → can't confirm; pointed at merge/save in AthleteOnboardingEngine + PlayerProfileStore. |
| 5 | WSLAutoEvaluator vs saved profile on Home | 23 | 59 | 82 | 608 | 0.006 | Can't confirm precedence without reading merge site in code. |
| 6 | Powerlifting weekly HubSetLog aggregation | 23 | 64 | 87 | 695 | 0.006 | Can't confirm pattern without tools; asked for HubSetLog snippet. |
| 7 | WearTearEngine after Hub complete | 25 | 65 | 90 | 785 | 0.006 | Suggested post-save / pre-regimen-refresh hook (unverified). |
| 8 | WuhuChatContext privacy trim | 24 | 87 | 111 | 896 | 0.007 | Strip IDs, location, raw health; prefer aggregates (generic without file read). |
| 9 | Live Activity vs HubSessionService | 28 | 89 | 117 | **1013** | 0.006 | ActivityKit lifecycle vs service-owned rest state; prefer `restEndsAt` for widget. |

**Final cumulative (estimated): 1013 tokens** across **9 questions**. Cap hit on turn 9 (crossed 950 after turn 8 at 896).

### Topics not reached (budget stop)

- `.kiro/specs/wuhu-core` next `tasks.md` items  
- PBT file placement under `WuhuTests/`  
- HealthKit refresh debounce on Home pull-to-refresh  

## Outcome vs prior session

| Session | Style | Approx. credits | Notes |
|---------|--------|-----------------|-------|
| [kiro-cli-guidance-2026-10-24.md](kiro-cli-guidance-2026-10-24.md) | One long prompt + `--trust-workspace` | ~1.49 | ~4293 prompt tokens in window; file reads |
| This marathon | 9× tiny prompts, no workspace trust | ~0.138 | ~1013 estimated prompt+answer tokens |
