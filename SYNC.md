# Local-first workflow

Edits happen in this project folder. **GitHub / Origin remotes are deferred** — wire those up later when you are ready.

## What to run

| Open this | Not this |
|---|---|
| **`HealthTracker.xcodeproj`** (repo root) | Individual `.swift` files |
| Scheme **HealthTracker**, then **Cmd+R** | `swift HealthTrackerApp.swift` |

App entry (automatic): [`HealthTracker/App/HealthTrackerApp.swift`](HealthTracker/App/HealthTrackerApp.swift). Full steps: [RUN.md](RUN.md).

## Open in Xcode (on this Mac)

```bash
cd /path/to/this/repo
open HealthTracker.xcodeproj
```

Signing (first run):

1. HealthTracker target → **Signing & Capabilities**
2. Team → your Personal Team  
3. Bundle Identifier → `com.elyaskhoubach.wuhu`  
4. Automatically manage signing → on  

## What “local” means right now

- App data: mock Health data / on-device SwiftData (no backend required)
- LLM keys: optional `Secrets.xcconfig` (git-ignored); otherwise local scoring fallback
- Source of truth: the files in this repo, not a remote visibility setting

## Later: GitHub integration

When you want remotes again:

1. Create a GitHub repo (empty, no README if this tree already has one)
2. Point `origin` at it and push `main`
3. Clone on other machines with `git clone` / Xcode SCM as usual

Until then, ignore Origin collaborator/visibility settings — personal Origin repos stay private by design and are optional for day-to-day builds.
