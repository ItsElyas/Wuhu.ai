# Home dashboard requirements

Source: `docs/UI_SPEC.md` sections 3–6.

## Greeting
- WHEN a display name exists, the greeting SHALL use its first word.
- WHEN the name is missing, the greeting SHALL say "there".
- WHEN a split is planned, the split title SHALL be accent-colored.
- WHEN the plan is rest, the copy SHALL be "we're taking a Rest Day today".
- WHEN there is no plan, the copy SHALL be "ready to train today?" with no accent.

## WSL Score and Sleep
- The WSL Score card SHALL show a tier name, not a 0–100 ring. Tiers, highest to lowest: Bron, BronLite, HTP, MTP, LTP, Sub-Player.
- UNTIL ranking exists, the card SHALL show Bron (`WSLRank.placeholder`), including in `HomeFixture.reference`.
- Sleep SHALL format as hours and minutes, never decimals. 462 minutes is "7h 42m". Under one hour is minutes only.

## Wear & Tear
- Injured and manual SHALL map to severe. Automatic sources SHALL NOT produce severe.
- Sore severity 3–5 or worked intensity above 0.7 SHALL be high. Lower sore or any positive worked intensity SHALL be slight.
- The highest level SHALL win. Mapping SHALL be monotonic in severity and intensity.
- On the front figure, the person's right side SHALL render on the viewer's left.

## Navigation and states
- Home SHALL be a NavigationStack root with no tab bar.
- Weekly Stats, Workout Hub, chat, body map, and the WSL Score sheet SHALL open the existing screens. The sheet shows the tier and readiness, effort, and sleep when present.
- Mock mode SHALL render `HomeFixture.reference`.
- Loading SHALL use skeletons, not zeros. Errors SHALL keep cached values and offer Retry.
