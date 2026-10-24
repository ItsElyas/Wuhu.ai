# Move to the Wuhu Xcode project

The app sources now live under **`Wuhu/`** with a **new** Xcode project so you are not stuck on stale `HealthTracker` file references.

## On your Mac

1. **Quit Xcode** completely.
2. Pull or copy this repo (or only the `Wuhu/`, `WuhuTests/`, `Config/`, and `Wuhu.xcodeproj` folders).
3. **Do not** open `HealthTracker.xcodeproj` — it was removed.
4. Open the new project:

   ```bash
   open Wuhu.xcodeproj
   ```

5. Scheme **Wuhu** → iPhone simulator (iOS 18+) → **Signing** → Team + bundle ID `com.elyaskhoubach.wuhu`.
6. **Product → Clean Build Folder**, then **Cmd+R**.

Entry point: `Wuhu/App/WuhuApp.swift` (`@main`).

## Optional: fresh folder

To avoid any old derived data:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*HealthTracker*
rm -rf ~/Library/Developer/Xcode/DerivedData/*Wuhu*
```

Then open `Wuhu.xcodeproj` again.

## Same app

Features, mock data, Chat, Vitality, Body Map, and bundle ID are unchanged — only the **project name and folder layout** changed.
