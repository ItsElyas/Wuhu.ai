# How to run Wuhu (local)

You do **not** run a single `.swift` file. iOS apps launch from Xcode.

## Steps

1. Open the **new** project (repo root):

   ```bash
   open Wuhu.xcodeproj
   ```

   Do **not** use `HealthTracker.xcodeproj` (removed). See [MIGRATION.md](MIGRATION.md).

2. In Xcode’s toolbar:
   - **Scheme:** `Wuhu`
   - **Destination:** any **iPhone** simulator on **iOS 18+**

3. **Signing** (once): target **Wuhu** → **Signing & Capabilities** → your **Team** → Bundle ID `com.elyaskhoubach.wuhu`

4. Press **Cmd+R** (Run).

Mock data is on by default (`-useMockData` in the scheme).

## Entry point

`Wuhu/App/WuhuApp.swift` (`@main` → `RootView`)

## Chat & Vitality (one file each)

| Tab | File |
|-----|------|
| Chat | `Wuhu/Features/Chat/ChatView.swift` |
| Vitality | `Wuhu/Features/Vitality/VitalityAgeView.swift` |

`RootView.swift` uses `ChatView()` and `VitalityAgeView()`.

## If build fails

- **Signing:** Team + `com.elyaskhoubach.wuhu` on the **Wuhu** target.
- **Stale HealthTracker errors:** you opened the old project or an old folder — use `Wuhu.xcodeproj` and clean derived data (see MIGRATION.md).
- **Cmd+R** on scheme **Wuhu** only — not Run on a single `.swift` file.
