# UI_SPEC.md — Home Screen ("Today")

Build the Home screen of HealthTracker in SwiftUI to match the reference image `docs/design/home-reference.png` (save the screenshot there and attach it in Cursor when running this spec). Follow `CLAUDE.md` for architecture, privacy, testing, and Kiro rules. Where this file and `CLAUDE.md` disagree about the Home screen, this file wins (see "Changes to CLAUDE.md").

**Goal:** pixel-close match to the reference at iPhone 16 Pro size (402 x 874 pt), working with live data and with mock data, light mode first.

> **Product note:** Home uses **WSL Score** and a tier, not the reference's 0–100 Ego Score or the number 82. Tiers, highest to lowest: Bron, BronLite, HTP, MTP, LTP, Sub-Player. Ranking is not implemented; the card shows **Bron** (`WSLRank.placeholder`). The label is "WSL Score", the bolt icon stays, and the tier name is the large value (no progress ring). The sheet is titled WSL Score and shows the tier plus readiness, effort, and sleep when those scores exist. `ScoreResult.ego_score` remains in the JSON for a later mapping and is not shown as a number. Sections below that still say Ego Score or 82 describe the original reference and are overridden by this note.

> Measurements below are derived from the screenshot assuming it is 2.5x a 402 pt-wide screen (px ÷ 2.5 = pt). Values are approximate. Build it, run it in the simulator next to the reference, and adjust until it matches within about 4 pt. If everything looks uniformly too big or small, scale proportionally by `screenWidth / 402` instead of changing individual values.

---

## 1. Screen overview (top to bottom)

1. Greeting headline (3 lines)
2. Row of two cards: **Ego Score** (left) and **Sleep** (right)
3. **Wear & Tear** card (full width): recommended targets (left), body figure (center), stat pills (right), legend (bottom)
4. **Weekly Stats** navigation row (full width pill)
5. **Workout Hub** navigation row (pill) + **chat button** (black circle, bottom right)

No tab bar. Navigation is `NavigationStack` rooted at Home. Everything scrolls vertically except the chat button, which floats.

```
HomeView
└── ZStack
    ├── MeshBackground                (fixed, ignores safe area)
    ├── ScrollView
    │   └── VStack(spacing: 14)
    │       ├── GreetingHeader
    │       ├── HStack(spacing: 13) { EgoScoreCard, SleepCard }
    │       ├── WearAndTearCard
    │       ├── NavRow("Weekly Stats", icon: chart.bar, trailing: chevron)
    │       └── HStack(spacing: 10) { NavRow("Workout Hub", icon: dumbbell), Color.clear(48pt) }
    └── ChatFAB                       (bottom trailing, floating)
```

Horizontal screen margin: **20 pt**. Add bottom scroll inset so the last row is never hidden behind the FAB or home indicator.

---

## 2. Design tokens (`DesignSystem/`)

### Colors (light)
| Token | Hex | Use |
|---|---|---|
| `ink` | `#0B1020` | Primary text, numbers |
| `textSecondary` | `#6B7794` | Card labels, captions, legend |
| `textTertiary` | `#9AA3B5` | Row labels in Wear & Tear |
| `accent` | `#E1453F` | "Push Day" text, Ego ring |
| `wearSlight` | `#EBCB6B` | Slight (yellow) |
| `wearHigh` | `#DE8A3A` | High (orange) |
| `wearSevere` | `#A82F27` | Severe (dark red) |
| `ringTrack` | `ink` at 8% | Ego ring track |
| `cardFill` | white at 70% | Top cards, pills (pills use 50%) |
| `wearCardFill` | white at 85% | Wear & Tear card |
| `navRowFill` | white at 30% | Weekly Stats / Workout Hub rows |
| `cardStroke` | white at 60%, 1 pt | Card borders |
| `divider` | `ink` at 6% | Line above legend |
| `fabFill` | `#0B0B0F` | Chat button |
| `bodyBase` | `#D8D7D2` | Neutral silhouette fill |
| `bodyOutline` | `#8A8A86` at 70%, 0.5 pt | Silhouette outline |

Dark mode (stretch, but do not ship it half-broken; if not done, lock the app to light with `.preferredColorScheme(.light)` and note it in the README): background mesh in deep navy/indigo, cards white at 8 to 12%, `ink` becomes near-white, `textSecondary` `#9AA6C4`.

### Background (`MeshBackground`)
Use `MeshGradient` (iOS 18), 3x3, fixed behind the scroll content, ignoring safe areas. Soft cream at top-left, pale blue at top-right, white/cream through the middle, pink on the right-middle to lower area, salmon at bottom-left, lavender at bottom-right.

```swift
MeshGradient(
    width: 3, height: 3,
    points: [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.5], [0.5, 0.5], [1, 0.5],
        [0, 1], [0.5, 1], [1, 1]
    ],
    colors: [
        Color(hex: 0xFDFBF8), Color(hex: 0xF1F6FA), Color(hex: 0xB7D9F3),
        Color(hex: 0xFDFBF8), Color(hex: 0xFBF6F7), Color(hex: 0xF4D3E3),
        Color(hex: 0xE98A70), Color(hex: 0xE88CBD), Color(hex: 0xC6B4EA)
    ]
)
.ignoresSafeArea()
```
Tune the colors against the reference; the top 40% is nearly white/cream with a blue tint at the top-right corner, and the pink/salmon/lavender takes over below the Wear & Tear card.

### Typography
Closest free match to the reference: **Plus Jakarta Sans** (SIL OFL). Bundle the font files, register them in `Info.plist` (`UIAppFonts`), add `Resources/Fonts/OFL.txt`, and credit it in the README. Fallback if loading fails: system font, heavy/bold weights. Use `Font.custom(_, size:, relativeTo:)` so text scales with Dynamic Type.

| Style | Size | Weight | Notes |
|---|---|---|---|
| `greeting` | 27 pt | ExtraBold | Tight leading (about 35 pt line pitch), tracking -0.5 |
| `bigValue` | 26 pt | Bold | "82", "7h 42m" |
| `cardLabel` | 13 pt | Medium | "Ego Score", "Sleep" |
| `caption` | 13 pt | Regular | "Deep 1h 50m", legend |
| `title` | 17 pt | Bold | "Wear & Tear", "Weekly Stats", "Workout Hub" |
| `rowLabel` | 13 pt | Regular | Wear & Tear left column labels |
| `rowValue` | 13 pt | SemiBold | Wear & Tear left column values |
| `recommendedHeader` | 13 pt | Bold | "Recommended" |
| `pillLabel` | 12 pt | Medium | "Steps", "Calories", "Recovery" |
| `pillValue` | 17 pt | Bold | "8,214", "1,940", "74%" |

### Shape and elevation
- Top cards: corner radius **28 pt**, continuous corners.
- Wear & Tear card: radius **30 pt**.
- Stat pills: radius **20 pt**.
- Nav rows: capsule (fully rounded).
- Shadow on cards: black at 6%, radius 24, y offset 8. Pills and nav rows: no shadow (or very faint).

```swift
struct GlassCard: ViewModifier {
    var radius: CGFloat = 28
    var fill: Color = Color.white.opacity(0.70)
    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 24, y: 8)
    }
}
```

---

## 3. Components

### 3.1 `GreetingHeader`
- Text: `Hello {firstName},` then a forced line break, then `we're training {Split} today`. Let it wrap naturally ("today" lands on line 3 at this width).
- Color `ink`. The split name ("Push Day") uses `accent`. Use a single `Text` built by concatenating styled `Text` segments so wrapping stays natural.
- `firstName` comes from the user profile `display_name` (first word). Fallback: "there".
- `Split` comes from today's plan: `push` → "Push Day", `pull` → "Pull Day", `legs` → "Leg Day", `upper` → "Upper Day", `lower` → "Lower Day", `full_body` → "Full Body Day".
- Rest day copy: `we're taking a Rest Day today`. No plan yet: `ready to train today?` with no accent.
- Top padding: about 8 pt below the safe area. Space below the greeting: 16 pt.
- Profile entry point (**not in the reference**, needed for sign out and editing onboarding answers): a 36 pt circular avatar button in the navigation bar, trailing, with a transparent nav bar. Remove it if the owner objects.

### 3.2 `WSLScoreCard` (left, 172 x 101 pt)
- Padding 15 pt. Top row: SF Symbol `bolt` (outline, 14 pt, `textSecondary`) + "WSL Score" (`cardLabel`).
- Primary value: the tier name (`bigValue`, `ink`), currently `Bron`. Longer names such as `Sub-Player` scale down to one line. No 0–100 ring.
- Tap: opens the WSL Score sheet (tier, plus readiness, effort, and sleep when present, and the existing vitality drivers and method).
- Ranking is not computed yet, so the card always shows `WSLRank.placeholder` (Bron), including when other metrics are empty.

### 3.3 `SleepCard` (right, 172 x 101 pt)
- Same padding and structure. Icon `moon` (outline), label "Sleep".
- `bigValue`: total sleep as `7h 42m`. Below, `caption` `textSecondary`: `Deep 1h 50m`.
- Format: hours and minutes only, never decimals. Under 1 hour shows `42m`.
- Tap: opens Sleep detail (stages chart).
- No data: "--" and caption "No sleep data".

### 3.4 `WearAndTearCard` (full width, about 358 x 238 pt)
- `wearCardFill`, radius 30, padding 17 pt.
- Title "Wear & Tear" (`title`, `ink`) top-left.
- **Three columns** under the title (inner width about 324 pt): left info column (flexible, about 119 pt), body figure (68 pt wide, 128 pt tall, centered), right pills column (120 pt). Gaps: 9 pt left of figure, 8 pt right of figure.

**Left column ("Recommended")**
- Header "Recommended" (`recommendedHeader`, `ink`), then four rows, about 18 pt row pitch, label left in `textTertiary`, value right-aligned in `ink`:
  - `Spec` → today's focus, e.g. "Upper body"
  - `Sleep` → target hours, e.g. "8h"
  - `Workout` → target minutes, e.g. "55 min"
  - `Cal` → target calories, e.g. "2,600"
- Keep the labels exactly as shown (`Spec`, `Sleep`, `Workout`, `Cal`).
- Vertically center this column against the figure.

**Center: `MiniBodyFigure`** (front view)
- Neutral gray silhouette (`bodyBase`, thin outline) with arms slightly away from the body, as in the reference.
- Region overlays filled by wear level: slight `wearSlight`, high `wearHigh`, severe `wearSevere`, none = no overlay. Overlays are nearly opaque (about 95%) and clipped exactly to each region.
- In the reference: shoulders/upper traps slight (yellow), chest high (orange), one thigh-to-ankle leg slight (yellow), the other severe (dark red).
- **Left/right rule:** `left*` and `right*` in `BodyPart` mean the person's own side. On a front-facing figure the viewer's left is the person's **right**. In the reference the viewer-left leg is yellow (`rightQuad`, `rightKnee`, `rightCalf`, ...) and the viewer-right leg is red (`left*`). Do not mirror this by accident.
- Front-view regions: `head`, `neck`, `leftShoulder`, `rightShoulder`, `chest`, `abs`, `leftBicep`, `rightBicep`, `leftForearm`, `rightForearm`, `leftHand`, `rightHand`, `leftHip`, `rightHip`, `leftQuad`, `rightQuad`, `leftKnee`, `rightKnee`, `leftCalf`, `rightCalf`, `leftAnkle`, `rightAnkle`, `leftFoot`, `rightFoot`.
- Back-only regions (`upperBack`, `lowerBack`, `glutes`, hamstrings, triceps) are not drawn. If any have a wear level, show a small muted label under the figure: `+N on back` (11 pt).
- Art: draw the silhouette and each region as an original vector. Preferred: one template vector per region in the asset catalog (Preserve Vector Data), stacked in a `ZStack` on an identical canvas and tinted per level. Acceptable placeholder: SwiftUI `Shape`s built from normalized ellipses and rounded rects, clearly marked `TODO: replace with final art`. No traced or copyrighted body art; record the art source in `Resources/Models/LICENSE.md`.
- Overlay fade-in 0.3 s on first appearance (skip with Reduce Motion).

**Right column: three `StatPill`s** (120 pt wide, about 40 pt tall, 7 pt gap, radius 20, fill white 50%)
- Two lines, left aligned, padding about 10 pt horizontal and 5 pt vertical: icon (14 pt) + label (`pillLabel`, `textSecondary`), then value (`pillValue`, `ink`).
- `Steps` (SF `figure.walk` or `shoeprints.fill`) → `8,214` (locale grouping separators)
- `Calories` (SF `flame`) → `1,940` (total calories burned today)
- `Recovery` (SF `heart.text.square`, or `waveform.path.ecg` if it is a closer match) → `74%`
- The first pill's left edge looks faded in the reference; that is just the translucent fill over the card. Do not add a gradient mask.
- Each pill is tappable (opens the matching detail screen).

**Bottom of the card**
- Hairline divider (`divider`) spanning the inner width, about 39 pt above the card bottom.
- Legend centered below it: three items with 8 pt dots and `caption` text: `Slight` (yellow), `High` (orange), `Severe` (dark red), about 16 pt apart.
- Tap anywhere on the card (except the pills) opens the full **Body Map** screen (3D view from `CLAUDE.md`).

### 3.5 `NavRow` ("Weekly Stats", "Workout Hub")
- Height 49 pt, capsule, fill `navRowFill` with `cardStroke`, no heavy shadow.
- Weekly Stats: leading icon `chart.bar` (18 pt, `ink`) 17 pt from the left edge, label `title` 12 pt after the icon, trailing `chevron.right` (semibold, 14 pt) 24 pt from the right edge. Full width (358 pt). Pushes `WeeklyStatsView`.
- Workout Hub: label `title`, trailing icon `dumbbell` (20 pt) 24 pt from the right edge. Width about 300 pt (full width minus the 48 pt chat button and a 10 pt gap). Pushes the Workouts hub (workout list plus "Recommended for you" from `CLAUDE.md`).
- Whole row is the tap target. Light haptic on tap. Pressed state: scale to 0.98.

### 3.6 `ChatFAB`
- 48 pt circle, fill `fabFill`, white SF Symbol `bubble.left` (22 pt) centered. Trailing aligned to the 20 pt margin and vertically aligned with the Workout Hub row, floating above the scroll content (bottom safe area respected).
- Tap presents `ChatView` as a sheet (medium and large detents).
- Accessibility label: "Open health chat".

---

## 4. Data contracts

`HomeViewModel` (`@Observable`, `@MainActor`) exposes one `HomeState`. It never imports HealthKit; it consumes the providers and services from `CLAUDE.md`.

```swift
struct HomeState {
    var firstName: String
    var plan: TodayPlan?                // split + focus
    var wslTier: WSLRank                // Bron until ranking exists
    var sleep: SleepSummary?            // total + deep
    var wear: [BodyPart: WearLevel]     // non-none only
    var recommendation: DailyRecommendation?
    var steps: Int?
    var caloriesBurned: Int?
    var recoveryPercent: Int?           // 0...100
    var phase: Phase                    // .loading, .loaded, .empty, .error(String)
}

enum WearLevel: Int, Comparable { case none, slight, high, severe }
enum Split: String { case push, pull, legs, upper, lower, fullBody = "full_body", rest }

struct DailyRecommendation {
    var focus: String          // "Upper body"
    var sleepHours: Double     // 8
    var workoutMinutes: Int    // 55
    var calories: Int          // 2600
}
```

**Wear level mapping** (replaces the yellow/red table in the Body Map section of `CLAUDE.md`):
- `severe` (dark red): part marked `injured` by the user. Never set automatically.
- `high` (orange): `sore` with severity 3 to 5, or `worked` intensity above 0.7.
- `slight` (yellow): `sore` with severity 1 to 2, or `worked` intensity above 0.
- `none`: otherwise.
- If a part has more than one source, the highest level wins.

**Where the numbers come from**
- `wslTier` is `WSLRank.placeholder` (Bron) until a ranking rule exists. `ScoreResult.ego_score` stays in JSON and is not the Home number. `recoveryPercent` ← `ScoreResult.readiness.score` (label it "Recovery" in the UI).
- `recommendation` and `plan` ← `ScoreResult.daily_recommendation` when available, otherwise `RecommendationEngine`'s deterministic fallback (rotate push/pull/legs and never plan a split that loads a `severe` part; avoid loading `high` parts).
- `sleep`, `steps`, `caloriesBurned` ← `HealthDataProviding` aggregates for today.
- `wear` ← `BodyPartStatus` records through the mapping above.

**Additions to `ScoreResult`** (also add to the scoring prompt and the Health JSON docs in `CLAUDE.md`; the LLM still only returns strict JSON):
```json
"ego_score": { "score": 82, "summary": "Strong sleep and low resting HR this week." },
"daily_recommendation": {
  "split": "push",
  "focus": "Upper body",
  "sleep_hours": 8.0,
  "workout_minutes": 55,
  "calories": 2600
}
```
Validate and clamp: `ego_score` 0 to 100, `sleep_hours` 5 to 11, `workout_minutes` 0 to 180, `calories` 1200 to 5000, `split` one of the enum values. Invalid values fall back to the local calculation.

---

## 5. States and behavior

- **Loading:** skeleton placeholders with the same shapes and sizes (shimmer, disabled with Reduce Motion). Never show zeros as if they were real data.
- **Empty / insufficient data:** dashes in numbers, empty ring, neutral figure, caption "Collecting data (X/7 days)". Recommendations show defaults from `RecommendationEngine`.
- **Error:** inline banner at the top with a Retry button; keep any cached values visible.
- **Pull to refresh** reloads HealthKit aggregates and, only if the snapshot changed, the cached `ScoreResult`.
- **Demo mode** ("Continue as Demo"): uses `MockHealthDataProvider`, `MockScoringService`, and `HomeFixture.reference`. The left card shows WSL tier Bron. The rest matches the reference (7h 42m, Deep 1h 50m, Upper body, 8h, 55 min, 2,600, Steps 8,214, Calories 1,940, Recovery 74%, shoulders slight, chest high, one leg slight, other leg severe). That fixture is for visual parity only; the real engine must not plan a Push Day while the chest is orange.
- **Per-user data:** all state is scoped to the signed-in user; signing out clears it.
- Light haptics on card and row taps. Reduce Motion disables the ring, overlay, and skeleton animations.

---

## 6. Accessibility

- Every card is one accessibility element with a full spoken value, e.g. "WSL Score, Bron", "Sleep 7 hours 42 minutes, deep sleep 1 hour 50 minutes".
- The body figure is an accessibility element with a generated label listing each affected part and level, e.g. "Wear and tear: chest high, right leg slight, left leg severe". Level is also conveyed by the legend text, not by color alone.
- Minimum 44 pt tap targets (the stat pills and nav rows qualify; expand hit areas if needed).
- Dynamic Type: text scales; at accessibility sizes (`dynamicTypeSize >= .accessibility1`) stack the Ego Score and Sleep cards vertically, and stack the Wear & Tear columns (info, then figure, then pills). Nothing may truncate or overlap.
- Contrast: check `textSecondary` and `textTertiary` against the card fill; darken them if they fail WCAG AA for the text sizes used.

---

## 7. Files to create

```
Features/Home/
├── HomeView.swift
├── HomeViewModel.swift
├── HomeState.swift
├── HomeFixture.swift                 (mock data matching the reference)
└── Components/
    ├── GreetingHeader.swift
    ├── EgoScoreCard.swift
    ├── SleepCard.swift
    ├── WearAndTearCard.swift
    ├── MiniBodyFigure.swift
    ├── StatPill.swift
    ├── NavRow.swift
    └── ChatFAB.swift
DesignSystem/
├── Colors.swift
├── Typography.swift
├── Metrics.swift
├── GlassCard.swift
└── MeshBackground.swift
Resources/Fonts/                      (Plus Jakarta Sans + OFL.txt)
docs/design/home-reference.png
```
Every component gets a `#Preview` using `HomeFixture.reference`, plus previews for loading, empty, and large Dynamic Type states, and a small iPhone (SE) size.

---

## 8. Changes to CLAUDE.md (apply these when implementing)

- Navigation: Home is the root `NavigationStack`. The `TabView` (Dashboard, Workouts, Chat, Vitality) is replaced by Home plus the Weekly Stats, Workout Hub, and chat entry points. Vitality Age moves into the Ego Score breakdown sheet.
- UI naming: "Ego Score" is the headline composite metric, and "Recovery" is the UI label for the former "Readiness". Keep using original names, never WHOOP's branding.
- Body Map colors: three levels (slight yellow, high orange, severe dark red) per the mapping in section 4. Red/severe is still never set automatically.
- Add `ego_score` and `daily_recommendation` to `ScoreResult` and the scoring prompt.

---

## 9. Tests and acceptance

**Unit tests** (include property tests where noted)
- Sleep duration formatting: `462 min → "7h 42m"`, `42 min → "42m"`, never negative or decimal.
- Number formatting uses locale grouping (`8214 → "8,214"`).
- Wear level mapping: injured always `severe`; auto sources never produce `severe`; highest level wins; mapping is monotonic with severity and intensity (property test).
- Greeting builder: each split, rest day, no plan, missing name.
- `ScoreResult` validation and clamping for the new fields.
- Left/right: `rightQuad` renders on the viewer's left of the front figure.

**Visual acceptance (compare to the reference at 402 pt width)**
- [ ] Background gradient colors and direction match (cool at the top right, warm pink/salmon/lavender at the bottom)
- [ ] Greeting wraps to the same 3 lines with "Push Day" in red
- [ ] Ego ring at 82 matches the gap position; ring and number sizes match
- [ ] Two top cards have equal size, spacing, radius, and translucency
- [ ] Wear & Tear columns line up: info rows right-aligned, figure centered, pills equal height
- [ ] Legend and divider match; dots and text spacing match
- [ ] Weekly Stats and Workout Hub rows are capsules of equal height; chat button aligned with Workout Hub
- [ ] No horizontal scroll; layout also works on iPhone SE and at largest Dynamic Type

Attach simulator screenshots of the matched screen to the pull request or README.

## 10. Kiro note

Per `CLAUDE.md`, build this in Kiro as well: create `.kiro/specs/home-dashboard/` with `requirements.md` (acceptance criteria from sections 3 to 6), `design.md` (components, tokens, data contracts), and `tasks.md` (section 7 files in build order), and log it in `KIRO_USAGE.md`.
