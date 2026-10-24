# Weekly performance design

`WeeklyPerformanceMode` plus `ProfilePreferences` (UserDefaults, default `.running`). `AppEnvironment` holds the preferences.

`WeeklyPerformanceContainerView` draws the mesh, Home back button, date pill, accent "Progress" title, and View Detailed Stats. It switches between `WeeklyRunningProgressView` and `WeeklyPowerliftingProgressView`.

Fixtures are static and match the reference screenshots. Real HealthKit wiring is later.
