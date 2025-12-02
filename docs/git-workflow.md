# Git Workflow Documentation

## Branch Strategy

### `main` branch (YOUR STABLE VERSION)
- **Purpose:** Protected stable version that you run in production
- **Tracks:** `origin/main` (your fork)
- **Protection:** GitHub branch protection enabled, requires PR for changes
- **Never:** Force push, direct commits, or fast-forward merges
- **Contains:** Your customizations (external_packages/, modified requirements.txt, etc.)

### `master` branch (UPSTREAM MIRROR)
- **Purpose:** Local mirror of official ComfyUI
- **Tracks:** `upstream/master` (comfyanonymous/ComfyUI)
- **Update:** `git checkout master && git pull` (fast-forward only)
- **Never:** Commit directly to this branch
- **Purpose:** Convenient reference for what's in upstream

## Update Process

When ComfyUI releases new updates:

1. **Update master mirror:**
   ```bash
   git checkout master
   git pull  # Fast-forward from upstream/master
   ```

2. **Create update branch:**
   ```bash
   git checkout main
   git checkout -b update-YYYY-MM-DD
   ```

3. **Merge upstream changes:**
   ```bash
   git merge master
   ```

   Handle conflicts if any (especially requirements.txt).

4. **Push update branch:**
   ```bash
   git push -u origin update-YYYY-MM-DD
   ```

5. **Create PR on GitHub:**
   - Go to https://github.com/YOURUSERNAME/ComfyUI
   - Create PR: `update-YYYY-MM-DD` → `main`
   - Review all changes in GitHub UI
   - Check for breaking changes in requirements.txt
   - Test locally before merging

6. **Test locally:**
   ```bash
   git checkout update-YYYY-MM-DD
   # Start ComfyUI and test workflows
   ```

7. **Merge PR when safe:**
   - If tests pass → Merge PR on GitHub
   - If tests fail → Fix issues in update branch, push, test again

8. **Clean up:**
   ```bash
   git checkout main
   git pull
   git branch -d update-YYYY-MM-DD
   git push origin --delete update-YYYY-MM-DD
   ```

## Critical Files to Watch

When reviewing update PRs, pay special attention to:

- `requirements.txt` - Package version jumps can break dependencies
- `comfy/model_management.py` - Memory management changes (async offload, etc.)
- `comfy/ops.py` - Core operations
- `nodes.py` - Node loading logic
- `server.py` - API changes

## Breaking Changes to Avoid

Known issues from previous updates:
- **Async offloading enabled by default** - Causes workflow failures on some systems
- **Large package version jumps** - transformers, workflow-templates
- **New required packages** - triton-windows, sageattention (may not install cleanly)

## Emergency Rollback

If an update breaks production:

```bash
# Identify last working commit
git log --oneline main

# Create rollback branch
git checkout -b rollback-YYYY-MM-DD main^

# Push and create PR
git push -u origin rollback-YYYY-MM-DD
# Create PR: rollback-YYYY-MM-DD → main
```

---

*Last updated: 2025-11-30*
