# ComfyUI Git Workflow Fix and Rollback Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Recover from broken upstream merges, establish protected fork workflow with PR-based updates to prevent future breaking changes.

**Architecture:** Create GitHub fork with protected `main` branch (stable working version) and tracking `master` branch (upstream mirror). All upstream updates go through PR review process before merging to main. Reset current repo to last working commit (d80b9216) while preserving local customizations.

**Tech Stack:** Git, GitHub, ComfyUI, Python 3.10.11

---

## Task 1: Recover to Last Working State

**Files:**
- Working directory: `/mnt/d/repos/ComfyUI`
- Git state: Currently at e7806123 (broken), target d80b9216 (working)

**Context:** Current master has breaking changes from upstream: async offloading enabled by default (9d8a8179), workflow-templates 0.2.11→0.7.25, transformers 4.37.2→4.50.3, and added triton-windows/sageattention to requirements.txt (ec9cbd02). Need to rollback while preserving local customizations in docs/plans/ and external_packages/.

**Step 1: Verify current commit state**

Run: `git log --oneline -5`

Expected output:
```
e7806123 Merge branch 'master' of https://github.com/comfyanonymous/ComfyUI new coommit.
65937603 Merge branch 'master' of https://github.com/comfyanonymous/ComfyUI updated fropmm remote
ec9cbd02 add  reqs
ae837bb8 Merge branch 'master' of https://github.com/comfyanonymous/ComfyUI
d80b9216 Merge branch 'master' of https://github.com/comfyanonymous/ComfyUI docs
```

**Step 2: Verify models and output are gitignored**

Run: `grep -E "^/(models|output)/" .gitignore`

Expected output:
```
/output/
/models/
```

This confirms models and output directories won't be touched by reset.

**Step 3: Check what will be preserved**

Run: `git status --short | head -20`

Expected: Shows modified files (mostly line endings) and untracked directories (docs/plans/, external_packages/)

**Step 4: Stash all local changes including untracked files**

Run: `git stash push -u -m "Save local customizations before rollback to d80b9216"`

Expected output:
```
Saved working directory and index state On master: Save local customizations before rollback to d80b9216
```

**Step 5: Verify stash was created**

Run: `git stash list`

Expected output:
```
stash@{0}: On master: Save local customizations before rollback to d80b9216
```

**Step 6: Reset to last working commit**

Run: `git reset --hard d80b9216`

Expected output:
```
HEAD is now at d80b9216 Merge branch 'master' of https://github.com/comfyanonymous/ComfyUI docs
```

**Step 7: Verify reset was successful**

Run: `git log --oneline -3`

Expected output:
```
d80b9216 Merge branch 'master' of https://github.com/comfyanonymous/ComfyUI docs
e6767913 [previous commit]
94c298f9 [previous commit]
```

Note: e7806123, 65937603, ec9cbd02, ae837bb8 should be gone from history.

**Step 8: Verify working directory is clean**

Run: `git status`

Expected output:
```
On branch master
Your branch is behind 'origin/master' by [N] commits, and can be fast-forwarded.
nothing to commit, working tree clean
```

**Step 9: Restore local customizations**

Run: `git stash pop`

Expected output:
```
On branch master
Untracked files:
  docs/plans/
  external_packages/

Changes not staged for commit:
  [various modified files]

Dropped refs/stash@{0}
```

**Step 10: Verify customizations are restored**

Run: `ls -la docs/plans/ external_packages/`

Expected: Both directories exist with their contents.

**Step 11: Check requirements.txt status**

Run: `git diff requirements.txt | head -20`

Expected: Shows additions of `triton-windows<3.5` and `sageattention` (from your stashed changes).

---

## Task 2: Test Working State Before Proceeding

**Files:**
- Python environment: `.venv/Scripts/python.exe` (Windows)
- Main script: `main.py`

**Context:** User will manually run a workflow that was failing with the broken commits. This verifies d80b9216 is actually the working state before we proceed with fork setup.

**Step 1: Set environment variables**

Run (in Windows PowerShell):
```powershell
$env:NUMEXPR_MAX_THREADS = "32"
```

Expected: No output (variable set silently).

**Step 2: Start ComfyUI**

Run (in Windows PowerShell):
```powershell
.venv\Scripts\python.exe main.py
```

Expected output should include:
- No `async offloading` messages (feature not enabled in d80b9216)
- All custom nodes load successfully
- Web server starts on `http://127.0.0.1:8188`

**Step 3: User manually tests workflow**

**USER ACTION REQUIRED:**
1. Open web browser to http://127.0.0.1:8188
2. Load a workflow that was failing with commits e7806123-65937603
3. Run the workflow to completion
4. Verify it completes without errors

**Step 4: Stop ComfyUI**

Press Ctrl+C in terminal to stop server.

**Step 5: Confirm working state**

**USER CONFIRMATION REQUIRED:** Did the workflow complete successfully?
- **YES** → Proceed to Task 3
- **NO** → Stop and diagnose what else is broken (d80b9216 might not be the right commit)

---

## Task 3: Create GitHub Fork

**Files:**
- GitHub web interface (manual steps)
- Local git config

**Context:** Create your own fork of ComfyUI on GitHub. This becomes the protected copy where you control what gets merged.

**Step 1: Open ComfyUI repo on GitHub**

**USER ACTION REQUIRED:**
1. Open browser to: https://github.com/comfyanonymous/ComfyUI
2. Click "Fork" button in top-right
3. Choose your GitHub account as the owner
4. Name: Keep as "ComfyUI"
5. Description: "Personal fork with custom configurations"
6. Uncheck "Copy the master branch only" (to get all branches)
7. Click "Create fork"

**Step 2: Verify fork was created**

**USER ACTION REQUIRED:**
1. You should be redirected to `https://github.com/YOURUSERNAME/ComfyUI`
2. Verify it shows "forked from comfyanonymous/ComfyUI"

**Step 3: Note your fork URL**

**USER ACTION REQUIRED:**
Copy the HTTPS clone URL. It should be:
```
https://github.com/YOURUSERNAME/ComfyUI.git
```

Replace `YOURUSERNAME` with your actual GitHub username.

**Step 4: Configure fork protection settings**

**USER ACTION REQUIRED:**
1. In your fork, go to Settings → Branches
2. Click "Add branch protection rule"
3. Branch name pattern: `main`
4. Check "Require a pull request before merging"
5. Check "Require approvals" (set to 1)
6. Click "Create"

This prevents accidentally pushing directly to main.

---

## Task 4: Reconfigure Git Remotes

**Files:**
- Local git config: `.git/config`

**Context:** Change current "origin" (pointing to upstream) to "upstream", add new "origin" pointing to your fork. This follows standard fork convention: origin=your repo, upstream=original repo.

**Step 1: Check current remotes**

Run: `git remote -v`

Expected output:
```
origin	https://github.com/comfyanonymous/ComfyUI (fetch)
origin	https://github.com/comfyanonymous/ComfyUI (push)
```

**Step 2: Rename origin to upstream**

Run: `git remote rename origin upstream`

Expected: No output (silent success).

**Step 3: Verify rename**

Run: `git remote -v`

Expected output:
```
upstream	https://github.com/comfyanonymous/ComfyUI (fetch)
upstream	https://github.com/comfyanonymous/ComfyUI (push)
```

**Step 4: Add your fork as origin**

**REPLACE `YOURUSERNAME` with your actual GitHub username:**

Run: `git remote add origin https://github.com/YOURUSERNAME/ComfyUI.git`

Expected: No output (silent success).

**Step 5: Verify both remotes exist**

Run: `git remote -v`

Expected output:
```
origin	https://github.com/YOURUSERNAME/ComfyUI.git (fetch)
origin	https://github.com/YOURUSERNAME/ComfyUI.git (push)
upstream	https://github.com/comfyanonymous/ComfyUI (fetch)
upstream	https://github.com/comfyanonymous/ComfyUI (push)
```

**Step 6: Fetch from both remotes**

Run: `git fetch --all`

Expected output:
```
Fetching origin
Fetching upstream
From https://github.com/comfyanonymous/ComfyUI
 * [new branch] ...
```

---

## Task 5: Create and Push Protected Main Branch

**Files:**
- Local branches: `master`, `main` (new)
- Remote branches: `origin/main` (new)

**Context:** Create `main` branch from current state (d80b9216 + your customizations). This becomes your protected stable branch. Keep `master` as upstream tracker.

**Step 1: Create main branch from current state**

Run: `git checkout -b main`

Expected output:
```
Switched to a new branch 'main'
```

**Step 2: Verify you're on main branch**

Run: `git branch`

Expected output:
```
  master
* main
```

**Step 3: Review what will be committed**

Run: `git status`

Expected: Shows untracked files (docs/plans/, external_packages/) and modified files (line endings, requirements.txt).

**Step 4: Add untracked directories to commit**

Run: `git add docs/plans/ external_packages/`

Expected: No output (silent success).

**Step 5: Check git status again**

Run: `git status`

Expected: Shows docs/plans/ and external_packages/ as "new file" entries, still shows modified files.

**Step 6: Review modified files**

Run: `git diff --stat`

Expected: Shows ~500 files modified (mostly line ending changes). This is expected for now.

**Step 7: Create .gitattributes to prevent future line ending issues**

Create file `.gitattributes`:

```
* text=auto
*.py text eol=lf
*.sh text eol=lf
*.ps1 text eol=crlf
*.md text eol=lf
*.json text eol=lf
*.yaml text eol=lf
*.yml text eol=lf
```

**Step 8: Add .gitattributes**

Run: `git add .gitattributes`

Expected: No output (silent success).

**Step 9: Commit current state (with line ending mess)**

Run:
```bash
git commit -m "chore: establish main branch at d80b9216 with local customizations

- Rollback from broken commits (e7806123, 65937603, ec9cbd02, ae837bb8)
- Preserve docs/plans/ directory (startup fixes documentation)
- Preserve external_packages/ directory (sageattention wheel)
- Add .gitattributes for line ending consistency
- Note: Line endings will be normalized in next commit

Rolled back due to breaking changes:
- Async offloading enabled by default (caused workflow failures)
- workflow-templates 0.2.11→0.7.25 (breaking changes)
- transformers 4.37.2→4.50.3 (incompatibilities)
- triton-windows/sageattention additions (installation issues)

This commit represents last known working state."
```

Expected output:
```
[main xxxxxxx] chore: establish main branch at d80b9216 with local customizations
 [N] files changed, [N] insertions(+), [N] deletions(-)
 create mode 100644 .gitattributes
 create mode 100644 docs/plans/...
 create mode 100644 external_packages/...
```

**Step 10: Push main branch to your fork**

Run: `git push -u origin main`

Expected output:
```
Enumerating objects: ...
Counting objects: ...
Writing objects: ...
To https://github.com/YOURUSERNAME/ComfyUI.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

**Step 11: Verify main exists on GitHub**

**USER ACTION REQUIRED:**
1. Go to https://github.com/YOURUSERNAME/ComfyUI
2. Verify "main" appears in branch dropdown
3. Verify it shows as default branch

**Step 12: Set main as default branch on GitHub**

**USER ACTION REQUIRED:**
1. Go to Settings → Branches
2. Under "Default branch", click switch icon
3. Select "main"
4. Click "Update"
5. Confirm the change

---

## Task 6: Configure Master as Upstream Tracker

**Files:**
- Local branch: `master`
- Remote tracking: `upstream/master`

**Context:** Configure `master` branch to track upstream ComfyUI. This branch always mirrors official ComfyUI, never commit directly to it.

**Step 1: Switch to master branch**

Run: `git checkout master`

Expected output:
```
Switched to branch 'master'
```

**Step 2: Reset master to exactly match upstream**

Run: `git reset --hard upstream/master`

Expected output:
```
HEAD is now at [commit] [message]
```

**Step 3: Configure master to track upstream/master**

Run: `git branch -u upstream/master master`

Expected output:
```
Branch 'master' set up to track remote branch 'master' from 'upstream'.
```

**Step 4: Verify tracking configuration**

Run: `git branch -vv`

Expected output:
```
* master [upstream/master] [commit message]
  main   [origin/main] chore: establish main branch...
```

**Step 5: Create branch protection note**

Create file `docs/git-workflow.md`:

```markdown
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
```

**Step 6: Add and commit workflow documentation**

Run:
```bash
git checkout main
git add docs/git-workflow.md
git commit -m "docs: add git workflow documentation for fork-based updates"
```

Expected output:
```
[main xxxxxxx] docs: add git workflow documentation for fork-based updates
 1 file changed, [N] insertions(+)
 create mode 100644 docs/git-workflow.md
```

**Step 7: Push documentation to fork**

Run: `git push`

Expected output:
```
To https://github.com/YOURUSERNAME/ComfyUI.git
   [commit]..[commit]  main -> main
```

---

## Task 7: Normalize Line Endings (Post-Testing)

**Files:**
- All tracked files with line ending issues
- Git config: `core.autocrlf`

**Context:** Now that we've verified d80b9216 works, clean up the line ending mess. This prevents ~500 files from showing as modified and makes future merges cleaner.

**Step 1: Verify you're on main branch**

Run: `git branch --show-current`

Expected output: `main`

**Step 2: Configure git to use LF endings**

Run: `git config core.autocrlf input`

Expected: No output (silent success).

**Step 3: Verify configuration**

Run: `git config core.autocrlf`

Expected output: `input`

This means: checkout files with LF, don't convert on commit.

**Step 4: Check current modified file count**

Run: `git status --short | wc -l`

Expected: Large number (~500) due to line ending changes.

**Step 5: Renormalize all files**

Run: `git add --renormalize .`

Expected: No output (silent processing).

**Step 6: Check what renormalization did**

Run: `git status`

Expected: Should show far fewer modified files (only files you actually changed, not line ending differences).

**Step 7: Review actual changes**

Run: `git diff --cached --stat`

Expected: Shows files that were actually modified beyond line endings (requirements.txt, etc.).

**Step 8: Commit normalized line endings**

Run:
```bash
git commit -m "chore: normalize line endings to LF

- Configure core.autocrlf=input for consistent LF endings
- Renormalize all tracked files via git add --renormalize
- Prevents future line ending conflicts when working between WSL and Windows
- Matches upstream ComfyUI line ending convention"
```

Expected output:
```
[main xxxxxxx] chore: normalize line endings to LF
 [N] files changed, [N] insertions(+), [N] deletions(-)
```

**Step 9: Push normalized state**

Run: `git push`

Expected output:
```
To https://github.com/YOURUSERNAME/ComfyUI.git
   [commit]..[commit]  main -> main
```

**Step 10: Verify clean working directory**

Run: `git status`

Expected output:
```
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

---

## Task 8: Test First Update Cycle (Dry Run)

**Files:**
- New branch: `update-test-YYYY-MM-DD`
- No actual changes, just testing the workflow

**Context:** Practice the update workflow with current state to make sure the process works before you need it for real updates.

**Step 1: Update master from upstream**

Run:
```bash
git checkout master
git pull
```

Expected output:
```
From https://github.com/comfyanonymous/ComfyUI
Already up to date.
```

Or if there are new commits:
```
Updating [old]..[new]
Fast-forward
 [files changed]
```

**Step 2: Switch back to main**

Run: `git checkout main`

Expected output:
```
Switched to branch 'main'
```

**Step 3: Create test update branch**

Run: `git checkout -b update-test-$(date +%Y-%m-%d)`

Expected output:
```
Switched to a new branch 'update-test-2025-11-30'
```

**Step 4: Merge master into update branch**

Run: `git merge master -m "test: merge upstream changes"`

Expected output (if master is ahead):
```
Merge made by the 'recursive' strategy.
 [files that changed]
```

Or if no changes:
```
Already up to date.
```

**Step 5: Handle conflicts if any**

If there are conflicts (especially in requirements.txt):

Run: `git status`

Look for "both modified" files.

**For requirements.txt conflicts:**
1. Open requirements.txt in editor
2. Look for conflict markers: `<<<<<<<`, `=======`, `>>>>>>>`
3. Keep your version for custom packages (triton-windows, sageattention)
4. Accept upstream versions for standard packages
5. Remove conflict markers
6. Save file

Run:
```bash
git add requirements.txt
git commit -m "chore: resolve requirements.txt conflicts, keep local customizations"
```

**Step 6: Push update branch to fork**

Run: `git push -u origin update-test-$(git branch --show-current | sed 's/update-test-//')`

Expected output:
```
To https://github.com/YOURUSERNAME/ComfyUI.git
 * [new branch]      update-test-2025-11-30 -> update-test-2025-11-30
```

**Step 7: Create PR on GitHub**

**USER ACTION REQUIRED:**
1. Go to https://github.com/YOURUSERNAME/ComfyUI
2. You should see a prompt: "update-test-YYYY-MM-DD had recent pushes"
3. Click "Compare & pull request"
4. Title: "Test Update: Upstream sync YYYY-MM-DD"
5. Description:
   ```
   Testing the update workflow with current upstream state.

   **Changes:**
   - [List key changes if any, or "No changes" if up to date]

   **Checklist:**
   - [ ] Reviewed requirements.txt changes
   - [ ] Checked for breaking changes in model_management.py
   - [ ] Tested locally
   - [ ] Verified custom packages preserved
   ```
6. Click "Create pull request"

**Step 8: Review PR in GitHub UI**

**USER ACTION REQUIRED:**
1. In the PR, click "Files changed" tab
2. Review each changed file
3. Look for:
   - requirements.txt: Are custom packages preserved?
   - model_management.py: Any async offload changes?
   - nodes.py: Any node loading changes?
   - server.py: Any API changes?

**Step 9: Test locally before merging**

The update branch is already checked out. Start ComfyUI:

Run (in Windows PowerShell):
```powershell
$env:NUMEXPR_MAX_THREADS = "32"
.venv\Scripts\python.exe main.py
```

**USER ACTION REQUIRED:**
1. Verify ComfyUI starts without errors
2. Run a test workflow
3. Verify workflow completes successfully

**Step 10: Merge or close PR**

**If tests passed:**

**USER ACTION REQUIRED:**
1. Go back to PR on GitHub
2. Click "Merge pull request"
3. Click "Confirm merge"
4. Click "Delete branch"

Then locally:
```bash
git checkout main
git pull
git branch -d update-test-2025-11-30
```

**If this was just a test and no changes:**

**USER ACTION REQUIRED:**
1. Go to PR on GitHub
2. Click "Close pull request" (don't merge)
3. Click "Delete branch"

Then locally:
```bash
git checkout main
git branch -D update-test-2025-11-30
git push origin --delete update-test-2025-11-30
```

---

## Completion Checklist

After all tasks complete, verify:

- [ ] Repository rolled back to d80b9216 (last working commit)
- [ ] Local customizations preserved (docs/plans/, external_packages/)
- [ ] Workflows tested and confirmed working
- [ ] GitHub fork created with branch protection on main
- [ ] Git remotes configured: origin=your fork, upstream=ComfyUI official
- [ ] main branch created, pushed, and set as default on GitHub
- [ ] master branch configured to track upstream/master
- [ ] Line endings normalized to LF with core.autocrlf=input
- [ ] Git workflow documentation created
- [ ] Test update cycle completed successfully

## Future Updates - Quick Reference

**Monthly upstream sync (when ComfyUI releases updates):**

```bash
# 1. Update master mirror
git checkout master && git pull

# 2. Create update branch
git checkout main
git checkout -b update-$(date +%Y-%m-%d)

# 3. Merge upstream
git merge master

# 4. Resolve conflicts (especially requirements.txt)
# Keep: triton-windows<3.5, sageattention, external_packages/
# Review: All version bumps, new dependencies

# 5. Push and create PR
git push -u origin update-$(date +%Y-%m-%d)
# Create PR on GitHub: update-YYYY-MM-DD → main

# 6. Review in GitHub UI (Files changed tab)
# 7. Test locally (run workflows)
# 8. Merge PR if tests pass
# 9. Clean up branch after merge
```

**Emergency rollback (if update breaks production):**

```bash
# 1. Check recent commits
git log --oneline main -10

# 2. Create rollback branch
git checkout -b rollback-$(date +%Y-%m-%d) main^

# 3. Push and create PR
git push -u origin rollback-$(date +%Y-%m-%d)
# Create PR on GitHub with explanation

# 4. Merge PR to restore previous state
```

---

## References

- Git Fork Workflow: https://www.atlassian.com/git/tutorials/comparing-workflows/forking-workflow
- Line Endings in Git: https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration#_core_autocrlf
- ComfyUI Repository: https://github.com/comfyanonymous/ComfyUI
- Previous Startup Fixes: See `docs/plans/2025-11-06-fix-comfyui-startup-issues.md`
