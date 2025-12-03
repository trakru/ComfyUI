# Git Workflow Documentation

## Branch Strategy

```
upstream/master → master (mirror) → feature/* (testing) → PR → main (stable)
```

### Three-Branch System

| Branch | Purpose | Tracks | Push To |
|--------|---------|--------|---------|
| `main` | Stable production version | `origin/main` | Your fork |
| `master` | Mirror of upstream ComfyUI | `upstream/master` | Never push |
| `feature/*` | Testing upstream updates | Created from `master` | Your fork |

### `main` branch (YOUR STABLE VERSION)
- **Purpose:** Protected stable version that you run in production
- **Contains:** Your customizations (external_packages/, modified configs, etc.)
- **Protection:** Only updated via merged PRs
- **Rule:** Never commit directly, never force push

### `master` branch (UPSTREAM MIRROR)
- **Purpose:** Read-only mirror of official ComfyUI
- **Tracks:** `upstream/master` (comfyanonymous/ComfyUI)
- **Update:** `git checkout master && git pull`
- **Rule:** Never commit to this branch, only pull from upstream

### `feature/*` branches (TESTING GROUND)
- **Purpose:** Test upstream updates before merging to main
- **Created from:** `master` (after syncing with upstream)
- **Naming:** `feature/update-YYYY-MM-DD` or `feature/test-<description>`
- **Rule:** Disposable - delete after PR merged or abandoned

---

## Update Process

### When ComfyUI releases new updates:

**Step 1: Sync master with upstream**
```bash
git checkout master
git pull
```

**Step 2: Create feature branch for testing**
```bash
git checkout -b feature/update-$(date +%Y-%m-%d) master
```

**Step 3: Test locally**
```powershell
# In Windows PowerShell
cd D:\repos\ComfyUI
$env:NUMEXPR_MAX_THREADS = "32"
.venv\Scripts\python.exe main.py
```
- Run your workflows
- Check for errors
- Verify custom nodes work

**Step 4a: If tests PASS**
```bash
# Push feature branch
git push -u origin feature/update-YYYY-MM-DD

# Create PR on GitHub: feature/update-YYYY-MM-DD → main
# Review changes in GitHub UI
# Merge PR
# Delete feature branch
git checkout main
git pull
git branch -d feature/update-YYYY-MM-DD
```

**Step 4b: If tests FAIL**
```bash
# Option A: Fix issues on feature branch
# Make fixes, commit, test again

# Option B: Abandon the update
git checkout main
git branch -D feature/update-YYYY-MM-DD
# Wait for upstream to fix, or investigate the issue
```

---

## Quick Reference Commands

### Daily workflow
```bash
# Check current branch
git branch

# Switch to main (stable)
git checkout main

# Switch to master (upstream mirror)
git checkout master
```

### Sync upstream
```bash
git checkout master
git pull
# master now matches upstream/master
```

### Test an update
```bash
git checkout master
git pull
git checkout -b feature/update-$(date +%Y-%m-%d)
# Test in Windows...
# If good: push and PR
# If bad: abandon branch
```

### Check what's new in upstream
```bash
git checkout master
git pull
git log main..master --oneline
# Shows commits in master not yet in main
```

### Compare your main vs upstream
```bash
git diff main..master --stat
# Shows files that differ between your stable and upstream
```

---

## Critical Files to Watch

When reviewing update PRs, pay special attention to:

| File | Why |
|------|-----|
| `requirements.txt` | Package version changes can break dependencies |
| `comfy/model_management.py` | Memory management, async offload changes |
| `comfy/ops.py` | Core operations |
| `nodes.py` | Node loading logic |
| `server.py` | API changes |

---

## Known Breaking Changes to Avoid

Issues from previous updates (November 2025):

| Change | Impact | Solution |
|--------|--------|----------|
| Async offloading enabled by default | Workflow crashes | Use `--disable-async-offload` flag |
| workflow-templates 0.2→0.7 | Template directory missing | Pin to working version |
| transformers 4.37→4.50 | Incompatibilities | Test before updating |

---

## Your Local Customizations

Files preserved in `main` that differ from upstream:

- `external_packages/` - sageattention wheel (pip install fails from git)
- `docs/plans/` - Implementation documentation
- `.gitattributes` - Line ending normalization

When merging upstream updates, ensure these are preserved.

---

## Emergency Rollback

If an update breaks production after merging to main:

```bash
# Find last working commit
git log --oneline main -10

# Create rollback PR
git checkout -b rollback-$(date +%Y-%m-%d) main~1
git push -u origin rollback-$(date +%Y-%m-%d)
# Create PR: rollback → main
# Merge immediately
```

---

## Remote Configuration

```
origin    git@github.com:trakru/ComfyUI.git     (your fork - push here)
upstream  https://github.com/comfyanonymous/ComfyUI  (official - pull only)
```

### Verify remotes
```bash
git remote -v
```

### Verify branch tracking
```bash
git branch -vv
```

Expected output:
```
* main   [origin/main] ...
  master [upstream/master] ...
```

---

*Last updated: 2025-12-01*
