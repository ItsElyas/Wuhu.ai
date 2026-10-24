# How to run HealthTracker (local)

You do **not** run a single `.swift` file. iOS apps launch from Xcode.

## Steps

1. Open the project (repo root):

   ```bash
   open HealthTracker.xcodeproj
   ```

2. In Xcode’s toolbar:
   - **Scheme:** `HealthTracker`
   - **Destination:** any **iPhone** simulator on **iOS 18+** (e.g. iPhone 16)

3. **Signing** (once): target **HealthTracker** → **Signing & Capabilities** → your **Team** → Bundle ID `com.elyaskhoubach.wuhu`

4. Press **Cmd+R** (Run).

Mock data is on by default (`-useMockData` is enabled in the scheme), so you do not need Apple Health or an API key.

## Entry point (reference)

The app starts here — Xcode uses this automatically when you run the scheme:

`HealthTracker/App/HealthTrackerApp.swift` (`@main` → `RootView`)

## If build fails

- **Signing:** pick a Team on the HealthTracker target.
- **Stale errors:** Product → **Clean Build Folder**, then Cmd+B.
- **Wrong copy of the project:** open the folder that contains `HealthTracker.xcodeproj` (this repo root).
