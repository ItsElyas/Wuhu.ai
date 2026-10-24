# Syncing this project (git pull)

Cloud Agent edits live on Origin and are pushed to `main`. Xcode only sees them after **you** pull on your Mac (the agent cannot run `git pull` on your machine).

## Browse / visibility

- Repo page: https://cursor.com/codebase/elyas-khoubach/Wuhu  
- **Wuhu is a personal-account repo.** On Origin, personal repos are **always Private**. There is no Visibility dropdown in Settings for personal repos — that control only exists on **team-owned** repos (Internal vs Private). Origin also has no “Public” visibility option.
- To share a personal repo: open the repo → **Settings** → **Collaborators** → invite people.
- To get team-wide “Internal” visibility, create/move the repo under a **team codebase** instead (team admin), then set Internal in that repo’s Settings → Access / General.
- This cloud agent cannot change visibility or collaborators for you (token is not scoped for those settings on Wuhu).

## First-time clone

```bash
curl -fsSL https://downloads.cursor.com/origin/install.sh | sh
origin auth login
origin repo clone elyas-khoubach/Wuhu
cd Wuhu
open HealthTracker.xcodeproj
```

If `origin` is not found:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Every time the agent says it pushed a fix

In the **same folder** that contains `HealthTracker.xcodeproj` (the one Xcode has open):

```bash
cd Wuhu
git checkout main
git pull origin main
```

Then in Xcode: **Product → Clean Build Folder**, then Cmd+B / Cmd+R.

### Confirm you pulled the right tree

```bash
# Should print nothing after a successful sync of recent ChatView / Vitality fixes:
grep -n 'alignment: \.stretch' HealthTracker/Features/Chat/ChatView.swift || true
grep -n 'let delta' HealthTracker/Features/Vitality/VitalityAgeView.swift || true

# Bundle id should be:
grep PRODUCT_BUNDLE_IDENTIFIER Config/Base.xcconfig
```

Expected bundle id: `com.elyaskhoubach.wuhu`

## If pull says “Already up to date” but Xcode still shows old errors

Xcode is open on a **different copy** of the project. Find it and pull there:

```bash
find ~ -name 'HealthTracker.xcodeproj' 2>/dev/null
```

Then `cd` into that parent folder, `git pull origin main`, and:

```bash
open HealthTracker.xcodeproj
```

## Signing (after pull)

1. Target **HealthTracker** → **Signing & Capabilities**
2. Team: your Personal Team  
3. Bundle Identifier: `com.elyaskhoubach.wuhu`  
4. Automatically manage signing: on  

## Docs

- Origin CLI: https://cursor.com/docs/origin/cli  
