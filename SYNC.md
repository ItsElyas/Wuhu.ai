# Syncing this project (git pull)

Cloud Agent edits live on Origin and are pushed to `main`. Xcode only sees them after **you** pull on your Mac (the agent cannot run `git pull` on your machine).

## Browse / visibility

- Repo page: https://cursor.com/codebase/elyas-khoubach/Wuhu  
- Visibility is **Private** by default. To change it: open that page → **Settings** → Visibility (Public / Internal / Private).  
  The cloud agent token cannot change visibility for you.

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
