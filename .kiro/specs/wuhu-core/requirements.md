# Wuhu core (R2 port)

## Requirements

- Home WSL Score SHALL use the R2 six-tier ladder when `PlayerProfileStore` holds a `wslEvaluation`.
- Workout prescriptions SHALL load from `Resources/workout_prescriptions.json` via `WorkoutDatabaseEngine`.
- Workout Hub SHALL log sets in SwiftData (`HubExercise`, `HubSetLog`) for future powerlifting weekly stats.
- Chat SHALL append dataset citations + athlete dossier to Gemini system instructions when a profile exists.
- Full interactive onboarding and live Kiro HTTP are out of scope for this milestone.
