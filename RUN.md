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

## Which Swift files matter (Chat & Vitality fixes)

These tabs were rebuilt under **new filenames** so Xcode stops compiling old broken views:

| Tab | Run this (via scheme) | Source file |
|-----|------------------------|-------------|
| Chat | `ChatScreen` in `RootView` | `HealthTracker/Features/Chat/ChatScreen.swift` |
| Vitality | `VitalityAgeScreen` in `RootView` | `HealthTracker/Features/Vitality/VitalityAgeScreen.swift` |

If Xcode still shows **`ChatView`** / **`.stretch`**, your Mac has an **old** `ChatView.swift`. Replace the whole file with the version from this repo (it only forwards to `ChatScreen`). Same for `VitalityAgeView.swift` → `VitalityAgeScreen`.

After pulling or copying files: **Product → Clean Build Folder**, then **Cmd+B**.

## If build fails

- **Signing:** pick a Team on the HealthTracker target; bundle ID `com.elyaskhoubach.wuhu`.
- **Stale errors:** Clean Build Folder, quit Xcode, reopen `HealthTracker.xcodeproj`.
- **Wrong copy of the project:** you must have `ChatScreen.swift` and **not** `ChatView.swift`. Compare with this repo or re-copy the whole `HealthTracker/` folder.
- **Do not** use Run on a single `.swift` file — only **Cmd+R** on the **HealthTracker** scheme.
