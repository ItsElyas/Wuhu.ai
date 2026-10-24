# Home dashboard design

## Tokens
`DesignSystem/Colors.swift`, `Typography.swift`, `Metrics.swift`, `GlassCard.swift`, `MeshBackground.swift`.

Light mesh is the reference. Home sets `.preferredColorScheme(.light)`. Typography uses the system font until Plus Jakarta Sans is bundled.

## Components
`Features/Home/Components/`: GreetingHeader, WSLScoreCard, SleepCard, WearAndTearCard, MiniBodyFigure, StatPill, NavRow, ChatFAB. Home shows `WSLRank.placeholder` (Bron).

`MiniBodyFigure` is a placeholder of original rounded rectangles. TODO: asset-catalog vectors.

## Data
`HomeState`, `HomeViewModel.makeState`, `HomeFixture.reference`.

`ScoreResult.ego_score` and `daily_recommendation` are decoded, clamped, and dropped when the plan is out of range. `HomeRecommendationFallback` rotates push/pull/legs and skips splits that load a high or severe part.

Mock mode (`useMockData`, including `-useMockData`) returns the fixture and does not run that planner, so the screenshot can show Push Day with an orange chest.
