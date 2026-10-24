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
10. Heal tips: tap a red (injured) body part to get part-specific wellness recovery recommendations (not medical advice)
11. Multi-user accounts: sign up, log in, log out, with per-user data separation
12. Onboarding intro: age, height, weight, activity level, sports played
13. Sport-based recommendations, including isometric exercises with step-by-step how-to and a hold timer

**Non-goals (do not build unless asked):** social features, Apple Watch app, in-app purchases, uploading raw Health data to a server.

## Building with Kiro (hackathon requirement, read first)

This project is entered in the Hackachusetts hackathon, **Healthcare & Biotech** track. The rules require that the project is built with Kiro and that insufficient use of Kiro can disqualify the entry. Treat Kiro as the **primary build tool**. Cursor or any other editor may be used only for small edits, never as a substitute for Kiro-driven development.

### Hard requirements
- The `/.kiro` directory exists at the repo root and is committed. **Never add `.kiro` or any subfolder to `.gitignore`.**
- The repo is public, contains all source, assets, and run instructions (see "Required Deliverables").
- A `KIRO_USAGE.md` write-up exists and is kept current (see below).
- Max 4 team members. Demo video under 3 minutes, publicly hosted, no third-party trademarks or copyrighted music.
- Do not use WHOOP, game, or other third-party trademarks in the app, README, or video.

### Kiro features to use and document
Use each of these for real, and note concrete examples as you go.

| Feature | How we use it on this project |
|---|---|
| **Spec-driven development** | One spec per feature in `.kiro/specs/<feature>/` with `requirements.md`, `design.md`, `tasks.md`. Specs: `auth-onboarding`, `healthkit-data`, `dashboard`, `scoring-pipeline`, `body-map`, `workouts`, `recommendations`, `chatbot`. Write or update the spec **before** coding the feature, then execute tasks from `tasks.md` and check them off. |
| **Steering docs** | `.kiro/steering/`: `product.md` (goals, users, tracks), `tech.md` (SwiftUI, iOS 18, HealthKit, Supabase, conventions), `structure.md` (folder layout), plus `health-privacy.md` (no raw health data off device, no diagnoses, disclaimers) and `swiftui-style.md`. Keep them short and specific; update when decisions change. |
| **Agent hooks** | `.kiro/hooks/`: e.g. on saving a Swift file run SwiftLint and the related tests; on changing `Core/Models` or the snapshot structs, regenerate/validate the JSON schema fixtures and update docs; on adding a feature, remind to update README and `KIRO_USAGE.md`; a check that `.kiro` is not gitignored and no secrets are staged. |
| **MCP** | `.kiro/settings/mcp.json`: e.g. a Supabase MCP server to inspect the schema and RLS policies, and an Xcode build/test MCP server so the agent can build and run tests itself. Document what each enabled that would have been slow or impossible. |
| **Property-based testing (PBT)** | Enable for requirements with clear invariants: Vitality Age calculator (never outside -10..+10, better inputs never raise the age), snapshot builder (30-day cap, rounding, no unavailable fields), `WorkoutLoadMapper`, body status rules (red never auto-set), onboarding validation ranges, `RecommendationEngine` (never recommends exercises loading an injured part). Record any bug PBT found that unit tests missed. |
| **Powers** | Use any relevant Kiro powers (for example for Supabase or testing best practices) and list which ones and why. |
| **Tools** | Prefer Kiro IDE for specs and agentic building. If Kiro CLI or other Kiro surfaces are also tried, note how they differed. |

### `KIRO_USAGE.md` (required, keep updated during the build)
Sections that answer the judges' questions directly:
1. Which Kiro tools were used (IDE, CLI, Web, Crew) and how they differed
2. Spec-driven development: how specs were structured, how it improved the process, comparison with vibe coding (include one concrete example of each)
3. Agent hooks: which workflows were automated and what improved
4. Steering docs: what strategy made the biggest difference
5. MCP: what it enabled
6. Property-based testing: what it caught
7. Powers and third-party integrations used
8. Short "what we would do differently" list

### Rules for the AI assistant when working in Kiro
- Start every non-trivial feature from a spec: requirements (EARS-style acceptance criteria), then design, then tasks.
- Keep `tasks.md` accurate. Mark tasks done only after building and testing.
- When you add a hook, steering file, MCP server, or PBT, append a short entry to `KIRO_USAGE.md` the same day.
- Never remove or hide `.kiro` content to "clean up" the repo.

## Tech Stack

- Language: Swift 5.9+
- UI: SwiftUI only (no UIKit unless a SwiftUI API does not exist)
- Min target: iOS 18 (needed for `RealityView` on iOS, used by the Body Map)
- 3D: RealityKit (`RealityView`). Do not use SceneKit; it is deprecated.
- Architecture: MVVM with `@Observable` (Observation framework)
- Data: HealthKit (source of truth for health data), SwiftData (workouts logged in-app, cached summaries, chat history)
- Charts: Swift Charts
- Concurrency: async/await, `@MainActor` for view models. No Combine unless needed.
- Backend / auth: Supabase (Auth + Postgres with Row Level Security) via the `supabase-swift` package
- Dependencies: `supabase-swift` is approved. Ask before adding any other Swift Package.

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
│   ├── Auth/             # SignInView, SignUpView, ForgotPasswordView, AuthViewModel, AuthService
│   ├── Onboarding/       # OnboardingFlow, step views, OnboardingViewModel, validation
│   ├── Recommendations/  # RecommendationEngine, SportPlans.json, ExerciseDetailView, HoldTimerView
│   ├── Profile/          # ProfileView (edit onboarding answers, sign out, delete account)
│   ├── BodyMap/          # BodyMapView, BodyMapViewModel, PartDetailSheet, BodyPartRegistry,
│   │                     # HealingRecommendations, BodyMap2DView, BodyMap3DView, WorkoutLoadMapper
│   └── Vitality/         # VitalityAgeView, breakdown
├── DesignSystem/         # Colors, Typography, reusable components
├── Resources/
│   └── Models/           # LICENSE.md, optional body.usdz
└── Tests/
    └── Fixtures/         # good_week / bad_week / sparse_data ScoreResult JSON
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
- Selecting a part with no status change should do nothing to saved data.
- Also provide an accessible list view (VoiceOver users cannot rely on the 3D scene): a list of all body parts with status and the same detail sheet.
- Swipe or toggle between Daily and Weekly view: Weekly shows a heat map of cumulative load per part over 7 days.
- Legend must use icons as well as color (e.g. `cross.case.fill` for injured, `exclamationmark.triangle.fill` for sore/worked) so status is not color-only.
- Accessibility hint on injured regions: "Opens healing recommendations".

### Heal tips (injured / red parts)
When the user taps a **red (injured)** body part — on the 2D map, 3D map, or the accessible list — `PartDetailSheet` must show a prominent **How to heal** section. This is a required Body Map feature.

- Source of truth: `HealingRecommendations` in `Features/BodyMap/HealingRecommendations.swift` (pure, testable; one recommendation set per `BodyPart`).
- Content for each part: short summary, 3–5 tips (protect/rest, ease back in, sleep/fuel, plus region-specific mobility or load swaps), and a "seek care when" note scaled by severity.
- Severity 4–5, or injured for 7+ days: stronger clinician / physical therapist suggestion (same rule as Safety and copy below).
- Copy rules: general wellness only — never diagnose, prescribe, or claim to treat. Use wording like "You marked this area as injured." Always show `HealingRecommendations.disclaimer`.
- Do **not** recommend training through a red part. Chat and `RecommendationEngine` must also refuse or filter exercises that load an injured part.
- Selecting Injured in the status control should reveal How to heal immediately (before Save), so the user sees tips while editing.
- Mock mode seeds at least one injured part (e.g. `rightKnee`) so heal tips are demoable without setup.

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
- Show a short disclaimer on the Body Map screen: tracking aid only, not medical advice. Mention that tapping a red part opens recovery tips that are wellness guidance only.
- The chatbot may read body status for context but must not tell the user to train through a red part. Prefer pointing the user at the Body Map heal tips for that part.

### Feeds the LLM scoring
Body status is included in the `HealthSnapshot` (see `body_status` in the schema) so the LLM can factor soreness and injuries into Readiness and Effort recommendations and explain them.

## HealthKit Rules

- Request read access only for: stepCount, heartRate, restingHeartRate, heartRateVariabilitySDNN, sleepAnalysis, activeEnergyBurned, basalEnergyBurned, workouts, dateOfBirth (optional).
- Add `NSHealthShareUsageDescription` to Info.plist with a clear, honest explanation. Enable the HealthKit capability.
- Wrap HealthKit in `HealthKitManager` behind a protocol (`HealthDataProviding`) so views and view models never import HealthKit directly.
- Use `HKStatisticsCollectionQuery` for daily/weekly aggregates; `HKSampleQuery` for sleep and workouts.
- Handle: authorization denied, no data, and simulator (HealthKit has limited data there). Provide a `MockHealthDataProvider` with realistic sample data and use it in previews and UI tests.
- Health data stays on device. Do not log raw health values to the console in release builds.

## Accounts, Login, and Multi-User Support

Login must genuinely work for multiple different users, each with their own profile and data. Use **Supabase Auth** with email + password. Sign in with Apple is a stretch goal only (it needs a paid Apple Developer account); do not make it required.

### Backend (`supabase/schema.sql`, committed)
```sql
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  age int check (age between 13 and 100),
  height_cm numeric check (height_cm between 100 and 250),
  weight_kg numeric check (weight_kg between 30 and 300),
  sex text check (sex in ('male','female','other','prefer_not_to_say')),
  activity_level text check (activity_level in
    ('sedentary','lightly_active','moderately_active','very_active','athlete')),
  experience_level text check (experience_level in ('beginner','novice','expert')),
  plays_sports boolean not null default false,
  sports jsonb not null default '[]'::jsonb,
  units text not null default 'imperial' check (units in ('imperial','metric')),
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "read own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "insert own profile" on public.profiles
  for insert with check (auth.uid() = id);
create policy "update own profile" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
```
- Row Level Security is mandatory so one user can never read or change another user's row. Add `supabase/tests/rls_test.sql` that proves it (user A cannot select or update user B's profile).
- Health data (HealthKit, workouts, body status) stays on the device. Only the profile row lives on the server.
- The app uses the project URL and the **anon** key only, from `Secrets.xcconfig`. Never put the `service_role` key in the app or repo.

### Flows
- Sign up: email, password (min 8 characters), confirm password, inline validation, friendly errors (email in use, weak password, offline).
- Sign in, sign out, forgot password (reset email), session persistence across launches (the SDK keeps the session in the Keychain), automatic token refresh.
- Delete account: removes the profile row and all local data for that user (via a Supabase RPC or Edge Function), with a confirmation dialog.
- Email confirmation: document in the README how to turn it off for local testing or how confirmation works.

### App state and routing
`AuthViewModel` exposes one of: `loading`, `signedOut`, `needsOnboarding`, `signedIn`. The root view switches on it. After sign in, if `onboarding_completed` is false, go to Onboarding; otherwise go to the Dashboard. Put Supabase behind an `AuthService` protocol with `SupabaseAuthService` and `MockAuthService`.

### Per-user data on one device
- Every SwiftData model (`BodyPartStatus`, workouts, cached `ScoreResult`, chat history, onboarding draft) has a `userId` and every query filters by the current user.
- On sign out, clear in-memory state and cached scores; the next user must see nothing of the previous user's data.
- Be honest in the UI and README: Apple Health data belongs to the phone, so two accounts on the same iPhone would see the same HealthKit data. Real health data is meant for one account per device; use demo mode when sharing a device.

### Judges and demo access
- Add a **Continue as Demo** button on the sign-in screen: no account, mock health data, mock scoring. This is also how someone can run the app with no Supabase project.
- Create a test account on the real Supabase project and put its email and password in the README "Testing" section, as the hackathon testing rules require when a project is private. Keep the project free to access.
- Include Supabase setup steps in the README: create a project, run `supabase/schema.sql` in the SQL editor, copy the URL and anon key into `Secrets.xcconfig`.

### Security
- Never store passwords in the app; never log credentials, tokens, or full emails in release builds.
- Validate inputs on the client and rely on the database `check` constraints as the real guard.
- Show generic messages for failed sign in (do not reveal whether an email exists).

### Tests
- Auth state machine with `MockAuthService`: signed out → sign up → needs onboarding → signed in → sign out.
- Two-user isolation: user A's workouts, body status, and scores are not visible after switching to user B.
- Password and email validation rules (include property tests).
- RLS script run against the Supabase project or a local Supabase instance.

## Onboarding Intro

Shown once after a new account is created (and re-runnable from Profile). A short, friendly multi-step flow with a progress indicator, Back and Next buttons, and inline validation. Required steps cannot be skipped.

1. **Welcome**: one screen on what the app does and what stays private (Health data stays on the phone).
2. **About you**
   - Age (whole number, 13 to 100; under 13 is blocked with a kind message)
   - Height (ft + in or cm) and weight (lb or kg), with a unit toggle. Default to imperial for US locale, metric otherwise. Store canonical metric values.
   - Sex is optional ("Prefer not to say" allowed); it is only used for age and sex adjusted norms.
   - Prefill height and weight from HealthKit if the user has already granted access; the user can edit.
   - Valid ranges: height 100 to 250 cm, weight 30 to 300 kg (match the database `check` constraints).
3. **Activity level** (single choice, with plain-language descriptions)
   - `sedentary`: little or no exercise
   - `lightly_active`: light exercise 1 to 3 days a week
   - `moderately_active`: moderate exercise 3 to 5 days a week
   - `very_active`: hard exercise 6 to 7 days a week
   - `athlete`: training twice a day or competing
4. **Experience level** (single choice, required, with plain-language descriptions)
   - `beginner`: new to exercise, or coming back after a long break (under about 6 months of steady training)
   - `novice`: some steady training, roughly 6 months to 2 years, comfortable with basic form
   - `expert`: 2+ years of steady training or competitive, comfortable with advanced variations
   - If unsure, suggest picking the lower level; it can be changed any time in Profile.
5. **Sports**
   - "Do you play any sports?" Yes / No.
   - If yes: multi-select sports (Basketball, Soccer, Football, Baseball/Softball, Volleyball, Tennis, Pickleball, Running/Track, Swimming, Cycling, Hockey, Lacrosse, Golf, Martial arts/Boxing, Rowing, Climbing, Weightlifting, Other with a text field). For each chosen sport, an optional skill level (`beginner`, `novice`, or `expert`; defaults to the overall experience level) and an "in season" toggle.
   - If no: continue, and still show general recommendations.
6. **Review and finish**: summary of answers (editable), then save to Supabase and local SwiftData, set `onboarding_completed = true`, and show the first recommendations.

Behavior:
- Save progress locally per user so quitting midway resumes where they left off.
- Answers feed the Health JSON snapshot `profile` block and the recommendation engine.
- Everything is editable later in the Profile screen.
- Accessible: labels, Dynamic Type, no color-only cues, steppers or pickers instead of tiny text fields where possible.
- Unit test validation and unit conversion (ft/in ↔ cm, lb ↔ kg) with property tests (round trips stay within rounding error).

## Sport-Based Recommendations

After onboarding, the app recommends exercises tailored to the user's sports, activity level, and body status. Recommendations include **isometric exercises** with a clear how-to.

### Design
- `RecommendationEngine` is a pure, deterministic Swift type. It reads the profile, sports, activity level, and `BodyPartStatus` and returns a ranked list of `Recommendation`.
- The exercise library lives in `Features/Recommendations/SportPlans.json` (easy to edit, no code changes). Each exercise has: `id`, `title`, `category` (`isometric`, `strength`, `mobility`, `recovery`, `conditioning`), `sports` it helps, `targetParts` (`BodyPart` raw values), `why` (one sentence), `steps` (numbered how-to), `prescription` (sets, `holdSeconds` or reps, `restSeconds`, `frequencyPerWeek`), `variations` (one each for `beginner`, `novice`, `expert`, with its own steps tweak and prescription), `safetyNotes`, and `minAge`.
- Every sport the user selects must produce at least 2 recommendations, with at least 1 isometric exercise where one applies.
- Scale prescriptions by **experience level first**, then adjust by activity level:
  - `beginner`: easiest variation, shorter holds (about 10 to 20 s), 2 sets, focus on form cues, no added weight, 2 to 3 days a week.
  - `novice`: standard variation, about 20 to 40 s, 3 sets, 3 days a week.
  - `expert`: harder variation (for example single-leg or weighted), about 30 to 60 s, 3 to 4 sets, with a progression suggestion (longer hold, added load, or less stable surface).
  - Activity level fine-tunes volume: `sedentary` and `lightly_active` trim sets and frequency; `very_active` and `athlete` allow the upper end of the range.
  - If experience level and activity level disagree (for example `expert` but `sedentary`), use the more conservative option.
  - Show the level on each exercise ("Beginner version") and let the user switch to an easier or harder variation. Suggest moving up a level after the user logs several completed sessions at the current one.
- Variation examples to include in the library:
  - Wall sit: beginner shallow squat (about 45 to 60 degrees), novice 90 degrees, expert single-leg or with a weight held at the chest.
  - Plank: beginner on knees or incline, novice full forearm plank, expert with feet elevated or alternating arm/leg lifts.
  - Glute bridge hold: beginner two-leg, novice two-leg with a longer hold, expert single-leg.
  - Isometric push-up hold: beginner incline or knees, novice standard half-way hold, expert full bottom hold or feet elevated.
- Optional LLM personalization: the LLM may only **choose and order exercise IDs from the library** and write a short personalized reason. It must not invent exercises or change prescriptions. Validate returned IDs; ignore unknown ones.
- Mapping starting point (edit freely): basketball, volleyball, pickleball → quads, knees, ankles, calves; soccer, running, lacrosse, hockey → glutes, hamstrings, core; tennis, pickleball, baseball → shoulders, core; climbing, martial arts → forearms, shoulders, core; football → all-round legs, core, neck.

### Starter isometric exercises (must be in the library with full how-to)
Each needs a numbered, beginner-friendly how-to. Starter set:
1. **Wall sit** (quads, glutes, knees): back flat on a wall, feet about shoulder-width and roughly two feet from the wall; slide down until knees are near 90 degrees and over the ankles; keep back flat and breathe normally; hold 20 to 45 s, 3 sets, 60 s rest, 3 days a week.
2. **Plank** (core, shoulders): forearms on the floor, elbows under shoulders; body in a straight line from head to heels; squeeze glutes and abs, do not let hips sag or pike; hold 20 to 40 s, 3 sets.
3. **Side plank** (obliques, hips): on one forearm with feet stacked, lift hips so the body is straight; hold 15 to 30 s each side, 2 to 3 sets.
4. **Glute bridge hold** (glutes, hamstrings, lower back): lie on back, knees bent, feet flat; lift hips until shoulders, hips, and knees form a line; squeeze glutes, ribs down; hold 20 to 40 s, 3 sets.
5. **Spanish squat hold** (quads, knees; band around a fixed post): lean back against the band with arms out, sit into a shallow squat with shins vertical; hold 20 to 40 s, 3 sets.
6. **Heel raise hold** (calves, ankles): rise onto toes and hold at the top, weight over the big toe; hold 15 to 30 s, 3 sets; support with a wall if needed.
7. **Isometric shoulder external rotation** (rotator cuff; for tennis, pickleball, baseball, swimming): stand sideways to a wall, elbow bent 90 degrees at your side, back of the hand against the wall; press gently into the wall without shrugging; hold 5 to 10 s, 5 reps, 2 sets.
8. **Isometric push-up hold** (chest, shoulders, triceps): lower to the bottom of a push-up (or half way), hold with a flat back; hold 10 to 20 s, 3 sets; use knees or an incline to scale.

### UI
- "Recommended for you" section at the top of the Workouts screen, grouped by sport, with a filter for isometrics.
- `ExerciseDetailView`: title, target body parts, why, numbered steps, safety notes, prescription, and a **hold timer** (`HoldTimerView`) with start/pause/reset, a set counter, rest countdown, and haptic cues. Respect Reduce Motion.
- "Mark done" logs a workout entry and bumps yellow `worked` intensity on the target body parts (via `WorkoutLoadMapper`).
- Use SF Symbols or simple original drawings for illustrations. No copyrighted images or videos.

### Safety rules (required)
- **Never recommend an exercise whose `targetParts` include a body part marked injured (red).** Filter it out and show a short note ("Skipped because your right knee is marked injured").
- For `sore` (yellow) parts, show a lighter variation or shorter hold instead of the full prescription.
- Remind users to breathe normally and never hold their breath during isometrics. Isometric holds can raise blood pressure, so add a note to check with a doctor first for anyone with high blood pressure, a heart condition, or who is pregnant.
- Stop and rest if there is sharp pain, dizziness, or numbness. Show a short "wellness tool, not medical advice" disclaimer on the recommendations screens.
- Users under 18: bodyweight-only exercises, no max-effort holds, and keep holds on the shorter end.
- The chatbot may explain exercises from the library but must not prescribe training through pain.

### Tests
- Engine returns at least 2 recommendations per selected sport, including an isometric where applicable.
- No recommendation targets an injured part (property test over random body status combinations).
- Prescriptions scale correctly with experience level, activity level, and age; output is deterministic for the same input.
- A beginner never receives an expert variation; mismatched experience and activity levels resolve to the more conservative option (property test).
- Every exercise has all three variations (`beginner`, `novice`, `expert`).
- Every `targetParts` value in the JSON is a valid `BodyPart`; every exercise has at least 3 steps and safety notes.

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
    "weight_kg": 76,
    "activity_level": "moderately_active",
    "experience_level": "novice",
    "sports": [
      { "name": "basketball", "level": "novice", "in_season": true },
      { "name": "pickleball", "level": "beginner", "in_season": false }
    ]
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
- `HealingRecommendations`: every `BodyPart` returns a non-empty tip list; high severity includes stronger seek-care copy; disclaimer string is non-empty.

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
2. **Features**: Daily/Weekly dashboard, steps, heart rate, sleep, calories, workouts, Body Map (including heal tips for injured/red parts), chatbot, Vitality Age and other scores, accounts/onboarding, sport recommendations
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
14. **Accounts and testing**: Supabase setup steps, the demo/test account credentials, and the "Continue as Demo" option
15. **How Kiro was used**: short summary linking to `KIRO_USAGE.md`, and a note that the `.kiro/` folder is included
16. **Hackathon info**: challenge track (Healthcare & Biotech) and a link to the demo video

### 2. `REQUIREMENTS.md`
List everything needed to run the project, with versions:
- macOS version able to run the current stable Xcode
- Xcode (latest stable; must include the iOS 18 or newer SDK)
- iOS Simulator runtime, iOS 18 or newer (or a physical iPhone on iOS 18 or newer)
- Apple ID signed into Xcode (free account is enough to run on your own device; HealthKit needs a real device or simulator, see below)
- A free Supabase project (URL and anon key) for login; not needed for "Continue as Demo"
- An LLM provider API key (optional: the app falls back to the local calculator without one)
- Kiro installed, if you want to explore the specs, hooks, and steering in `.kiro/`
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
- Mock mode must populate all screens: Daily, Weekly, Workouts, Body Map (a couple of yellow and one red part — tapping the red part must show How to heal), Vitality Age, and Chat.

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
9. Follow the "Building with Kiro" section: spec first, keep `.kiro/` committed, and log Kiro usage in `KIRO_USAGE.md`.
10. Auth, onboarding, and recommendations are core features. Do not stub login: it must work for multiple real users through Supabase, with Row Level Security.

## Suggested Build Order

1. Kiro setup first (`.kiro/steering`, first specs, hooks, MCP), then project setup, folder structure, design system basics
2. Mock data layer + models + dashboard UI (Daily, then Weekly)
2b. Supabase project + `schema.sql` with RLS, `AuthService`, sign up / sign in / sign out, then Onboarding and Profile, with per-user local data and a demo mode
3. HealthKit integration behind the provider protocol
4. Workouts screen with SwiftData
4a. `RecommendationEngine`, `SportPlans.json`, exercise detail screen with hold timer (needs onboarding profile and Body Map status)
4b. Body Map: `BodyPart` enum + `BodyPartStatus` model + 2D body map first, then the 3D RealityKit view, then `WorkoutLoadMapper` auto-yellow, then `HealingRecommendations` + How to heal in `PartDetailSheet` for injured parts
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
- Two different accounts can sign up, complete onboarding, and see only their own data
- Onboarding collects age, height, weight, activity level, experience level (beginner, novice, expert), and sports, and drives the recommendations
- Tapping a red (injured) Body Map part opens heal tips (`HealingRecommendations`) with disclaimer; no diagnosis language
- `.kiro/` is committed (not gitignored) and contains steering, specs, hooks, and MCP config
- `KIRO_USAGE.md` is complete and the demo video is under 3 minutes
