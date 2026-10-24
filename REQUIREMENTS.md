# Requirements — HealthTracker

Everything needed to build and run this project.

| Requirement | Version / notes |
|---|---|
| macOS | Version able to run the current stable Xcode (typically latest macOS or previous) |
| Xcode | Latest stable, with the **iOS 18 or newer** SDK |
| iOS Simulator runtime | **iOS 18+** (or a physical iPhone on iOS 18+) |
| Apple ID | Signed into Xcode (free account is enough to run on your own device) |
| LLM API key | **Optional.** Without it, Vitality Age / Readiness / Effort / Sleep Score use the on-device `VitalityAgeCalculator` |
| Homebrew + SwiftLint | Optional |
| Swift packages | **None** |

## Simulator vs device

- **Simulator:** HealthKit data is limited; many Home and Weekly metrics will show dashes.
- **Physical iPhone:** Real HealthKit reads work after you grant permission. Enable Developer Mode on the phone for deployment. This is the supported way to see live stats.

## Secrets

1. Copy `Secrets.example.xcconfig` to `Secrets.xcconfig` (git-ignored).
2. Set `LLM_API_KEY`, `LLM_BASE_URL`, and `LLM_MODEL` if you want live AI scoring.
3. Set `GEMINI_API_KEY` for Gemini chat (`GEMINI_MODEL` and `GEMINI_BASE_URL` are optional); optional — local chat fallback works without it.
4. Optional MyNetDiary: `MYNETDIARY_API_KEY`, `MYNETDIARY_BASE_URL`, and `MYNETDIARY_USER_ID`. Leave the key as the placeholder to read calorie intake from Apple Health instead.

Keys are injected into Info.plist via build settings. Never commit real keys.
