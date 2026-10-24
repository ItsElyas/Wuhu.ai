# Sync code between Cloud Agent and your Mac

## Which repo has the latest Wuhu project?

| Remote | URL | Latest `main`? |
|--------|-----|----------------|
| **Agent mirror (use this to pull)** | `https://origin.cursor.com/git/elyas-khoubach/tmp-35a06042bcb4d8af.git` | Yes — Cloud Agent pushes here after every change |
| **Your Wuhu repo** | `https://origin.cursor.com/git/elyas-khoubach/Wuhu.git` | Only if you pushed or merged agent work into it |

The agent **cannot** push to `elyas-khoubach/Wuhu` from this environment (403). Pull from the **agent mirror** first, then optionally push to `Wuhu` from your Mac.

## Pull on your Mac (recommended)

### Option A — Fresh folder (clearest)

```bash
cd ~/Developer   # or wherever you keep projects
git clone https://origin.cursor.com/git/elyas-khoubach/tmp-35a06042bcb4d8af.git Wuhu
cd Wuhu
open Wuhu.xcodeproj
```

Sign in to Origin when Git asks. Scheme **Wuhu** → **Cmd+R**. See [MIGRATION.md](MIGRATION.md) if you used `HealthTracker.xcodeproj` before.

### Option B — Update an existing folder

```bash
cd /path/to/your/Wuhu-or-HealthTracker-folder
git remote remove agent 2>/dev/null
git remote add agent https://origin.cursor.com/git/elyas-khoubach/tmp-35a06042bcb4d8af.git
git fetch agent
git checkout main
git merge agent/main
# or, if you want to match agent exactly (discards local uncommitted work):
# git reset --hard agent/main
open Wuhu.xcodeproj
```

### Option C — Point `origin` at the agent mirror

```bash
cd /path/to/your/repo
git remote set-url origin https://origin.cursor.com/git/elyas-khoubach/tmp-35a06042bcb4d8af.git
git pull origin main
open Wuhu.xcodeproj
```

## After you have the code on your Mac

Push to your personal **Wuhu** repo (if you use it):

```bash
git remote add wuhu https://origin.cursor.com/git/elyas-khoubach/Wuhu.git
git push wuhu main
```

## What to run in Xcode

| Open this | Not this |
|---|---|
| **`Wuhu.xcodeproj`** | `HealthTracker.xcodeproj` (removed) |
| Scheme **Wuhu**, **Cmd+R** | Running a single `.swift` file |

Entry: [`Wuhu/App/WuhuApp.swift`](Wuhu/App/WuhuApp.swift). Run steps: [RUN.md](RUN.md).

Signing: **Wuhu** target → Team → bundle ID `com.elyaskhoubach.wuhu`.

## Later: GitHub

When ready, add GitHub as `origin` and push `main` — same tree as after pulling the agent mirror.
