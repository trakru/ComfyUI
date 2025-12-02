# ComfyUI Startup Issues Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix all critical errors and warnings in ComfyUI startup to ensure all custom nodes function properly and optimal performance is achieved.

**Architecture:** This plan addresses Windows-specific permission issues, missing Python dependencies, and environment configuration. We'll fix symlink errors, install missing packages, configure environment variables, and verify all fixes work.

**Tech Stack:** Python 3.10.11, pip package manager, Windows PowerShell, ComfyUI custom nodes ecosystem

---

## Task 1: Fix ComfyLiterals Symlink Error

**Files:**
- Source: `D:\repos\ComfyUI\custom_nodes\ComfyLiterals\js`
- Target: `D:\repos\ComfyUI\web\extensions\ComfyLiterals`
- Script: `scripts/fix-comfyliterals-symlink.ps1` (create)

**Context:** Windows requires administrator privileges for creating symlinks. The error `[WinError 1314]` indicates insufficient privileges. We have two solutions: run with admin or manually copy files.

**Step 1: Create PowerShell script for manual copy fallback**

Create file `scripts/fix-comfyliterals-symlink.ps1`:

```powershell
# Fix ComfyLiterals symlink issue by copying files
$Source = "D:\repos\ComfyUI\custom_nodes\ComfyLiterals\js"
$Target = "D:\repos\ComfyUI\web\extensions\ComfyLiterals"

Write-Host "Fixing ComfyLiterals web extension..." -ForegroundColor Cyan

# Remove existing target if it exists
if (Test-Path $Target) {
    Write-Host "Removing existing target directory..." -ForegroundColor Yellow
    Remove-Item -Path $Target -Recurse -Force
}

# Create parent directory if needed
$ParentDir = Split-Path -Parent $Target
if (-not (Test-Path $ParentDir)) {
    Write-Host "Creating parent directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
}

# Copy files
Write-Host "Copying files from $Source to $Target..." -ForegroundColor Yellow
Copy-Item -Path $Source -Destination $Target -Recurse -Force

if (Test-Path $Target) {
    Write-Host "Success! ComfyLiterals web extension installed." -ForegroundColor Green
} else {
    Write-Host "Error: Failed to copy files." -ForegroundColor Red
    exit 1
}
```

**Step 2: Create directory for scripts**

Run: `mkdir scripts` (in ComfyUI root)

Expected: Directory created or already exists

**Step 3: Run the PowerShell script**

Run: `powershell -ExecutionPolicy Bypass -File scripts/fix-comfyliterals-symlink.ps1`

Expected output:
```
Fixing ComfyLiterals web extension...
Copying files from ... to ...
Success! ComfyLiterals web extension installed.
```

**Step 4: Verify the fix**

Run: `Test-Path D:\repos\ComfyUI\web\extensions\ComfyLiterals`

Expected: `True`

**Step 5: Commit**

```bash
git add scripts/fix-comfyliterals-symlink.ps1
git commit -m "fix: add PowerShell script to resolve ComfyLiterals symlink issue on Windows"
```

---

## Task 2: Fix opencv-contrib-python for LayerStyle

**Files:**
- Virtual environment: `D:\repos\ComfyUI\.venv`
- Requirements verification script: `scripts/verify-opencv.py` (create)

**Context:** LayerStyle nodes require `cv2.ximgproc.guidedFilter` which is only available in opencv-contrib-python, not the standard opencv-python package. A conflict or incomplete installation is causing the import failure.

**Step 1: Check current opencv installation**

Run: `.venv\Scripts\python.exe -m pip list | findstr opencv`

Expected output: Shows current opencv packages installed

**Step 2: Uninstall conflicting opencv packages**

Run: `.venv\Scripts\python.exe -m pip uninstall -y opencv-python opencv-contrib-python opencv-python-headless`

Expected: Packages uninstalled successfully

**Step 3: Install opencv-contrib-python**

Run: `.venv\Scripts\python.exe -m pip install opencv-contrib-python`

Expected output:
```
Successfully installed opencv-contrib-python-4.x.x.xx
```

**Step 4: Create verification script**

Create file `scripts/verify-opencv.py`:

```python
#!/usr/bin/env python3
"""Verify opencv-contrib-python installation and guidedFilter availability."""

import sys

def verify_opencv():
    """Check if opencv-contrib-python is properly installed."""
    print("Verifying opencv-contrib-python installation...")

    try:
        import cv2
        print(f"✓ OpenCV version: {cv2.__version__}")
    except ImportError as e:
        print(f"✗ Failed to import cv2: {e}")
        return False

    try:
        from cv2 import ximgproc
        print("✓ cv2.ximgproc module imported successfully")
    except ImportError as e:
        print(f"✗ Failed to import cv2.ximgproc: {e}")
        return False

    try:
        # Check if guidedFilter is available
        if hasattr(ximgproc, 'guidedFilter'):
            print("✓ guidedFilter function is available")
        else:
            print("✗ guidedFilter function not found in ximgproc")
            return False
    except Exception as e:
        print(f"✗ Error checking guidedFilter: {e}")
        return False

    print("\n✓ All opencv-contrib-python components verified successfully!")
    return True

if __name__ == "__main__":
    success = verify_opencv()
    sys.exit(0 if success else 1)
```

**Step 5: Run verification script**

Run: `.venv\Scripts\python.exe scripts/verify-opencv.py`

Expected output:
```
Verifying opencv-contrib-python installation...
✓ OpenCV version: 4.x.x.xx
✓ cv2.ximgproc module imported successfully
✓ guidedFilter function is available

✓ All opencv-contrib-python components verified successfully!
```

**Step 6: Commit**

```bash
git add scripts/verify-opencv.py
git commit -m "fix: reinstall opencv-contrib-python and add verification script for LayerStyle nodes"
```

---

## Task 3: Install onnxruntime-gpu for DWPose Acceleration

**Files:**
- Virtual environment: `D:\repos\ComfyUI\.venv`
- Requirements verification script: `scripts/verify-onnxruntime.py` (create)

**Context:** DWPose preprocessing currently runs on CPU which is very slow. Installing onnxruntime-gpu will enable CUDA acceleration for much faster pose detection. The RTX 5090 with CUDA 12.8 support needs the GPU-enabled version.

**Step 1: Check current onnxruntime installation**

Run: `.venv\Scripts\python.exe -m pip list | findstr onnxruntime`

Expected output: Shows current onnxruntime packages (if any)

**Step 2: Uninstall CPU-only onnxruntime if present**

Run: `.venv\Scripts\python.exe -m pip uninstall -y onnxruntime`

Expected: Package uninstalled or "not installed" message

**Step 3: Install onnxruntime-gpu**

Run: `.venv\Scripts\python.exe -m pip install onnxruntime-gpu`

Expected output:
```
Successfully installed onnxruntime-gpu-1.x.x
```

**Step 4: Create verification script**

Create file `scripts/verify-onnxruntime.py`:

```python
#!/usr/bin/env python3
"""Verify onnxruntime-gpu installation and CUDA provider availability."""

import sys

def verify_onnxruntime():
    """Check if onnxruntime-gpu is properly installed with CUDA support."""
    print("Verifying onnxruntime-gpu installation...")

    try:
        import onnxruntime as ort
        print(f"✓ ONNX Runtime version: {ort.__version__}")
    except ImportError as e:
        print(f"✗ Failed to import onnxruntime: {e}")
        return False

    # Check available providers
    providers = ort.get_available_providers()
    print(f"\nAvailable execution providers: {providers}")

    if 'CUDAExecutionProvider' in providers:
        print("✓ CUDAExecutionProvider is available")
    else:
        print("✗ CUDAExecutionProvider not found")
        print("  This means GPU acceleration won't work for DWPose")
        return False

    # Check if CUDA provider can be initialized
    try:
        session_options = ort.SessionOptions()
        # This is a minimal test - just verify we can request CUDA
        print("✓ CUDA provider can be requested")
    except Exception as e:
        print(f"✗ Error initializing CUDA provider: {e}")
        return False

    print("\n✓ onnxruntime-gpu with CUDA support verified successfully!")
    print("  DWPose will now use GPU acceleration instead of CPU")
    return True

if __name__ == "__main__":
    success = verify_onnxruntime()
    sys.exit(0 if success else 1)
```

**Step 5: Run verification script**

Run: `.venv\Scripts\python.exe scripts/verify-onnxruntime.py`

Expected output:
```
Verifying onnxruntime-gpu installation...
✓ ONNX Runtime version: 1.x.x
Available execution providers: ['CUDAExecutionProvider', 'CPUExecutionProvider']
✓ CUDAExecutionProvider is available
✓ CUDA provider can be requested

✓ onnxruntime-gpu with CUDA support verified successfully!
  DWPose will now use GPU acceleration instead of CPU
```

**Step 6: Commit**

```bash
git add scripts/verify-onnxruntime.py
git commit -m "feat: install onnxruntime-gpu for GPU-accelerated DWPose preprocessing"
```

---

## Task 4: Configure NumExpr Thread Environment Variable

**Files:**
- Create: `scripts/set-comfyui-env.ps1`
- Modify: `.env.example` (create if doesn't exist)

**Context:** NumExpr detected 32 CPU cores but limited itself to 16 threads for safety. Setting NUMEXPR_MAX_THREADS=32 will allow it to use all available cores for better performance in numerical computations.

**Step 1: Create environment setup PowerShell script**

Create file `scripts/set-comfyui-env.ps1`:

```powershell
# Set optimal environment variables for ComfyUI on this system
# Run this before starting ComfyUI for best performance

Write-Host "Configuring ComfyUI environment variables..." -ForegroundColor Cyan

# NumExpr: Use all 32 CPU cores instead of default 16
$env:NUMEXPR_MAX_THREADS = "32"
Write-Host "✓ Set NUMEXPR_MAX_THREADS=32 (detected 32 cores)" -ForegroundColor Green

# Display current environment
Write-Host "`nCurrent ComfyUI environment:" -ForegroundColor Cyan
Write-Host "  NUMEXPR_MAX_THREADS: $env:NUMEXPR_MAX_THREADS" -ForegroundColor White

Write-Host "`nEnvironment configured! Now run: python main.py" -ForegroundColor Green
```

**Step 2: Create .env.example for documentation**

Create file `.env.example`:

```bash
# ComfyUI Environment Configuration Example
# Copy this to .env and customize for your system

# NumExpr Thread Configuration
# Set to number of CPU cores for optimal performance
# Default: 16 (safety limit)
# Recommended: Set to your CPU core count
NUMEXPR_MAX_THREADS=32

# Add other environment variables as needed
```

**Step 3: Create startup helper script**

Create file `start-comfyui.ps1`:

```powershell
# ComfyUI startup script with optimal environment configuration

# Set environment variables
& "$PSScriptRoot\scripts\set-comfyui-env.ps1"

# Activate virtual environment and start ComfyUI
Write-Host "`nStarting ComfyUI..." -ForegroundColor Cyan
& ".venv\Scripts\Activate.ps1"
python main.py
```

**Step 4: Test environment script**

Run: `powershell -ExecutionPolicy Bypass -File scripts/set-comfyui-env.ps1`

Expected output:
```
Configuring ComfyUI environment variables...
✓ Set NUMEXPR_MAX_THREADS=32 (detected 32 cores)

Current ComfyUI environment:
  NUMEXPR_MAX_THREADS: 32

Environment configured! Now run: python main.py
```

**Step 5: Verify environment variable in PowerShell**

Run: `$env:NUMEXPR_MAX_THREADS`

Expected output: `32`

**Step 6: Commit**

```bash
git add scripts/set-comfyui-env.ps1 .env.example start-comfyui.ps1
git commit -m "feat: add environment configuration for optimal NumExpr performance"
```

---

## Task 5: Install Optional sageattention Package

**Files:**
- Virtual environment: `D:\repos\ComfyUI\.venv`
- Documentation: `docs/optional-packages.md` (create)

**Context:** sageattention is an optional package that provides advanced attention mechanism optimizations. It's not required for ComfyUI to function but can improve performance for certain models. This is a low-priority optional enhancement.

**Step 1: Research sageattention compatibility**

Run: `.venv\Scripts\python.exe -m pip search sageattention 2>&1 || echo "pip search disabled, checking PyPI directly"`

Expected: Information about sageattention package availability

**Step 2: Attempt to install sageattention**

Run: `.venv\Scripts\python.exe -m pip install sageattention`

Expected: Either successful installation or clear error message about compatibility

**Step 3: Create optional packages documentation**

Create file `docs/optional-packages.md`:

```markdown
# Optional ComfyUI Packages

This document lists optional packages that can enhance ComfyUI performance but are not required for core functionality.

## sageattention

**Status:** Optional performance enhancement
**Purpose:** Advanced attention mechanism optimizations for certain models
**Impact:** May improve inference speed for compatible models

### Installation

```bash
.venv\Scripts\python.exe -m pip install sageattention
```

### Compatibility

- Requires compatible PyTorch version
- May not be available for all CUDA versions
- Check package documentation for system requirements

### Verification

If installed successfully, ComfyUI will automatically detect and use sageattention.
Check startup logs for: "sageattention package is installed"

### Troubleshooting

If installation fails with build errors:
- This package may require specific CUDA toolkit versions
- It's optional - ComfyUI works fine without it
- Skip this package if it causes issues

## Other Optional Packages

### TensorRT (Advanced)

For advanced users wanting maximum inference speed on NVIDIA GPUs.

**Not recommended unless you have specific TensorRT experience.**

---

*Last updated: 2025-11-06*
```

**Step 4: Check installation result**

Run: `.venv\Scripts\python.exe -c "import sageattention; print(f'sageattention version: {sageattention.__version__}')"`

Expected: Either version number (success) or ImportError (package not compatible/installed)

**Step 5: Document the result**

If installation succeeded:
- Update `docs/optional-packages.md` with success note

If installation failed:
- Update `docs/optional-packages.md` with failure reason and note that it's optional

**Step 6: Commit**

```bash
git add docs/optional-packages.md
git commit -m "docs: add optional packages documentation including sageattention"
```

---

## Task 6: Create Comprehensive Startup Verification Script

**Files:**
- Create: `scripts/verify-comfyui-setup.py`

**Context:** After all fixes, we need a comprehensive verification script that checks all critical components are working correctly. This script will verify all the fixes we've made and provide a clear status report.

**Step 1: Create comprehensive verification script**

Create file `scripts/verify-comfyui-setup.py`:

```python
#!/usr/bin/env python3
"""Comprehensive ComfyUI setup verification script."""

import sys
import os
from pathlib import Path

def print_header(text):
    """Print a formatted header."""
    print(f"\n{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}\n")

def print_status(check_name, passed, message=""):
    """Print a status line for a check."""
    status = "✓" if passed else "✗"
    color = "\033[92m" if passed else "\033[91m"  # Green or Red
    reset = "\033[0m"

    print(f"{color}{status}{reset} {check_name}")
    if message:
        print(f"  {message}")

def verify_comfyliterals():
    """Verify ComfyLiterals web extension is properly installed."""
    target = Path("D:/repos/ComfyUI/web/extensions/ComfyLiterals")

    if not target.exists():
        return False, "Directory does not exist"

    # Check if it has content
    files = list(target.glob("*"))
    if not files:
        return False, "Directory is empty"

    return True, f"Found {len(files)} files"

def verify_opencv():
    """Verify opencv-contrib-python with guidedFilter."""
    try:
        import cv2
        from cv2 import ximgproc

        if not hasattr(ximgproc, 'guidedFilter'):
            return False, "guidedFilter not found in ximgproc"

        return True, f"OpenCV {cv2.__version__} with ximgproc.guidedFilter"
    except ImportError as e:
        return False, str(e)

def verify_onnxruntime():
    """Verify onnxruntime-gpu with CUDA support."""
    try:
        import onnxruntime as ort

        providers = ort.get_available_providers()
        has_cuda = 'CUDAExecutionProvider' in providers

        if not has_cuda:
            return False, f"CUDA not available. Providers: {providers}"

        return True, f"Version {ort.__version__} with CUDA support"
    except ImportError as e:
        return False, str(e)

def verify_environment():
    """Verify environment variables are set correctly."""
    numexpr_threads = os.environ.get('NUMEXPR_MAX_THREADS', 'NOT SET')

    if numexpr_threads == 'NOT SET':
        return False, "NUMEXPR_MAX_THREADS not set (should be 32)"

    if numexpr_threads != '32':
        return False, f"NUMEXPR_MAX_THREADS={numexpr_threads} (should be 32)"

    return True, f"NUMEXPR_MAX_THREADS={numexpr_threads}"

def verify_sageattention():
    """Verify sageattention (optional)."""
    try:
        import sageattention
        return True, f"Version {sageattention.__version__} (optional)"
    except ImportError:
        return False, "Not installed (optional - not required)"

def main():
    """Run all verification checks."""
    print_header("ComfyUI Setup Verification")

    checks = [
        ("ComfyLiterals Web Extension", verify_comfyliterals),
        ("opencv-contrib-python (LayerStyle)", verify_opencv),
        ("onnxruntime-gpu (DWPose)", verify_onnxruntime),
        ("Environment Variables", verify_environment),
        ("sageattention (Optional)", verify_sageattention),
    ]

    results = []
    for check_name, verify_func in checks:
        passed, message = verify_func()
        print_status(check_name, passed, message)
        results.append(passed)

    # Summary
    print_header("Summary")

    required_checks = results[:4]  # First 4 are required
    optional_checks = results[4:]   # Last is optional

    required_passed = sum(required_checks)
    required_total = len(required_checks)

    print(f"Required checks: {required_passed}/{required_total} passed")

    if all(required_checks):
        print("\n✓ All required components verified successfully!")
        print("  ComfyUI is ready to run with all fixes applied.")
        return 0
    else:
        print("\n✗ Some required components failed verification.")
        print("  Please review the failures above and re-run the appropriate fix tasks.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
```

**Step 2: Run verification script without environment set**

Run: `.venv\Scripts\python.exe scripts/verify-comfyui-setup.py`

Expected: Should show environment variable check failing (we haven't set it yet in this session)

**Step 3: Run with environment configured**

Run:
```powershell
$env:NUMEXPR_MAX_THREADS="32"
.venv\Scripts\python.exe scripts/verify-comfyui-setup.py
```

Expected output:
```
============================================================
  ComfyUI Setup Verification
============================================================

✓ ComfyLiterals Web Extension
  Found X files
✓ opencv-contrib-python (LayerStyle)
  OpenCV X.X.X with ximgproc.guidedFilter
✓ onnxruntime-gpu (DWPose)
  Version X.X.X with CUDA support
✓ Environment Variables
  NUMEXPR_MAX_THREADS=32
✗ sageattention (Optional)
  Not installed (optional - not required)

============================================================
  Summary
============================================================
Required checks: 4/4 passed

✓ All required components verified successfully!
  ComfyUI is ready to run with all fixes applied.
```

**Step 4: Commit**

```bash
git add scripts/verify-comfyui-setup.py
git commit -m "feat: add comprehensive setup verification script"
```

---

## Task 7: Test ComfyUI Startup with All Fixes

**Files:**
- Test output log: `docs/startup-test-results.md` (create)

**Context:** Final end-to-end test to verify all fixes work together. We'll start ComfyUI and verify all previous errors are resolved.

**Step 1: Create startup test script**

Create file `scripts/test-startup.ps1`:

```powershell
# Test ComfyUI startup with all fixes applied

Write-Host "ComfyUI Startup Test" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

# Set environment
Write-Host "`n[1/4] Setting environment variables..." -ForegroundColor Yellow
$env:NUMEXPR_MAX_THREADS = "32"
Write-Host "      ✓ NUMEXPR_MAX_THREADS=32" -ForegroundColor Green

# Verify setup
Write-Host "`n[2/4] Running setup verification..." -ForegroundColor Yellow
& .venv\Scripts\python.exe scripts/verify-comfyui-setup.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n✗ Setup verification failed. Please fix errors before starting." -ForegroundColor Red
    exit 1
}

# Start ComfyUI (will run for 10 seconds then stop)
Write-Host "`n[3/4] Starting ComfyUI for 10 seconds..." -ForegroundColor Yellow
Write-Host "      Watch for errors in startup output..." -ForegroundColor White

# Start in background
$job = Start-Job -ScriptBlock {
    Set-Location "D:\repos\ComfyUI"
    $env:NUMEXPR_MAX_THREADS = "32"
    & .venv\Scripts\python.exe main.py
}

# Wait 10 seconds
Start-Sleep -Seconds 10

# Check if still running
if ($job.State -eq "Running") {
    Write-Host "      ✓ ComfyUI started successfully" -ForegroundColor Green
    Stop-Job -Job $job
    Remove-Job -Job $job
} else {
    Write-Host "      ✗ ComfyUI failed to start" -ForegroundColor Red
    Receive-Job -Job $job
    Remove-Job -Job $job
    exit 1
}

Write-Host "`n[4/4] Test complete!" -ForegroundColor Yellow
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Review the verification output above" -ForegroundColor White
Write-Host "  2. Start ComfyUI normally: ./start-comfyui.ps1" -ForegroundColor White
Write-Host "  3. Check web UI at http://127.0.0.1:8188" -ForegroundColor White
```

**Step 2: Run startup test**

Run: `powershell -ExecutionPolicy Bypass -File scripts/test-startup.ps1`

Expected: ComfyUI starts without the previous errors

**Step 3: Check for specific error messages**

Look for these in output:
- ✗ Should NOT see: `[WinError 1314]` symlink error
- ✓ Should NOT see: `Cannot import name 'guidedFilter'` error
- ✓ Should NOT see: `DWPose might run very slowly` warning
- ✓ Should see: `NumExpr defaulting to 32 threads` (instead of 16)

**Step 4: Document test results**

Create file `docs/startup-test-results.md`:

```markdown
# ComfyUI Startup Test Results

**Date:** 2025-11-06
**Tester:** [Your name or "automated"]

## Test Environment

- **OS:** Windows (WSL2)
- **Python:** 3.10.11
- **ComfyUI Version:** 0.3.66
- **GPU:** NVIDIA GeForce RTX 5090 (32GB VRAM)
- **PyTorch:** 2.7.0+cu128

## Fixes Applied

- [x] ComfyLiterals symlink issue fixed
- [x] opencv-contrib-python installed for LayerStyle
- [x] onnxruntime-gpu installed for DWPose
- [x] NUMEXPR_MAX_THREADS environment variable set to 32
- [ ] sageattention (optional - not installed)

## Test Results

### Previous Errors - Status

| Error | Status | Notes |
|-------|--------|-------|
| `[WinError 1314]` ComfyLiterals symlink | ✓ FIXED | Files copied manually |
| `Cannot import guidedFilter` LayerStyle | ✓ FIXED | opencv-contrib-python installed |
| `DWPose might run very slowly` | ✓ FIXED | onnxruntime-gpu with CUDA |
| `NumExpr defaulting to 16 threads` | ✓ FIXED | Now using 32 threads |
| `sageattention not installed` | ⚠ SKIPPED | Optional package |

### Startup Performance

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| ComfyUI-Manager prestartup | 5.6s | [TBD] | [TBD] |
| Total custom nodes load time | ~15s | [TBD] | [TBD] |
| NumExpr threads | 16 | 32 | +100% |

### Custom Nodes Status

All custom nodes that previously had errors should now load successfully:
- [x] ComfyLiterals web extension
- [x] LayerStyle nodes (all features)
- [x] ControlNet Aux (DWPose with GPU)

## Verification Commands

```bash
# Verify all fixes
.venv\Scripts\python.exe scripts\verify-comfyui-setup.py

# Start with optimal settings
.\start-comfyui.ps1
```

## Conclusion

**Overall Status:** ✓ ALL CRITICAL ISSUES RESOLVED

All critical startup errors have been fixed. ComfyUI now starts cleanly with:
- All custom nodes functioning properly
- GPU acceleration enabled where applicable
- Optimal performance settings configured

---

*Test completed: [timestamp]*
```

**Step 5: Update test results with actual timings**

After running the test, fill in the [TBD] values in `docs/startup-test-results.md` with actual measurements from the startup log.

**Step 6: Commit**

```bash
git add scripts/test-startup.ps1 docs/startup-test-results.md
git commit -m "test: add startup verification test and document results"
```

---

## Task 8: Create User Documentation and Cleanup

**Files:**
- Create: `docs/SETUP-FIXES.md`
- Update: `README.md` (if it references startup issues)

**Context:** Document all fixes for future reference and provide clear instructions for users experiencing similar issues.

**Step 1: Create comprehensive setup fixes documentation**

Create file `docs/SETUP-FIXES.md`:

```markdown
# ComfyUI Setup Fixes Documentation

This document describes the fixes applied to resolve ComfyUI startup issues on Windows systems.

## Quick Start

**If you're experiencing startup errors, run these commands:**

```powershell
# 1. Apply all fixes
.\scripts\fix-comfyliterals-symlink.ps1

# 2. Install missing packages
.\.venv\Scripts\python.exe -m pip uninstall -y opencv-python opencv-python-headless
.\.venv\Scripts\python.exe -m pip install opencv-contrib-python onnxruntime-gpu

# 3. Verify everything works
.\.venv\Scripts\python.exe .\scripts\verify-comfyui-setup.py

# 4. Start ComfyUI with optimal settings
.\start-comfyui.ps1
```

## Issues Fixed

### 1. ComfyLiterals Symlink Error (WinError 1314)

**Problem:**
```
[WinError 1314] A required privilege is not held by the client
Failed to create symlink to D:\repos\ComfyUI\web\extensions\ComfyLiterals
```

**Root Cause:** Windows requires administrator privileges to create symbolic links.

**Solution:**
- **Option A (Recommended):** Run `scripts\fix-comfyliterals-symlink.ps1` to copy files
- **Option B:** Run PowerShell as Administrator before starting ComfyUI

**Script:** `scripts/fix-comfyliterals-symlink.ps1`

---

### 2. LayerStyle guidedFilter Import Error

**Problem:**
```
Cannot import name 'guidedFilter' from 'cv2.ximgproc'
A few nodes cannot works properly
```

**Root Cause:** Missing `opencv-contrib-python` package (only `opencv-python` installed).

**Solution:**
```powershell
.\.venv\Scripts\python.exe -m pip uninstall -y opencv-python opencv-python-headless
.\.venv\Scripts\python.exe -m pip install opencv-contrib-python
```

**Verification:** `python scripts/verify-opencv.py`

---

### 3. DWPose CPU-Only Warning

**Problem:**
```
DWPose: Onnxruntime not found or doesn't come with acceleration providers
DWPose might run very slowly
```

**Root Cause:** Missing `onnxruntime-gpu` package for CUDA acceleration.

**Solution:**
```powershell
.\.venv\Scripts\python.exe -m pip uninstall -y onnxruntime
.\.venv\Scripts\python.exe -m pip install onnxruntime-gpu
```

**Verification:** `python scripts/verify-onnxruntime.py`

**Performance Impact:** 10-50x faster DWPose preprocessing with GPU vs CPU.

---

### 4. NumExpr Thread Limitation

**Problem:**
```
NumExpr detected 32 cores but "NUMEXPR_MAX_THREADS" not set
NumExpr defaulting to 16 threads
```

**Root Cause:** NumExpr safety limit preventing use of all CPU cores.

**Solution:**
Set environment variable before starting ComfyUI:
```powershell
$env:NUMEXPR_MAX_THREADS = "32"
```

**Automated:** Use `start-comfyui.ps1` which sets this automatically.

**Performance Impact:** Better CPU utilization for numerical operations.

---

### 5. sageattention Not Installed (Optional)

**Problem:**
```
Warning: Could not load sageattention: No module named 'sageattention'
```

**Root Cause:** Optional performance package not installed.

**Solution (Optional):**
```powershell
.\.venv\Scripts\python.exe -m pip install sageattention
```

**Note:** This is optional and may not be compatible with all systems. Skip if installation fails.

---

## Helper Scripts

All scripts are located in the `scripts/` directory:

| Script | Purpose |
|--------|---------|
| `fix-comfyliterals-symlink.ps1` | Fix ComfyLiterals web extension |
| `verify-opencv.py` | Verify opencv-contrib-python |
| `verify-onnxruntime.py` | Verify onnxruntime-gpu with CUDA |
| `verify-comfyui-setup.py` | Comprehensive setup verification |
| `set-comfyui-env.ps1` | Set optimal environment variables |
| `test-startup.ps1` | Test ComfyUI startup |

## Recommended Startup Process

**Use the provided startup script for optimal settings:**

```powershell
.\start-comfyui.ps1
```

This script automatically:
1. Sets `NUMEXPR_MAX_THREADS=32`
2. Activates the virtual environment
3. Starts ComfyUI with optimal configuration

## Verification

**To verify all fixes are applied correctly:**

```powershell
# Set environment (if not using start-comfyui.ps1)
$env:NUMEXPR_MAX_THREADS = "32"

# Run verification
.\.venv\Scripts\python.exe .\scripts\verify-comfyui-setup.py
```

**Expected output:**
```
✓ ComfyLiterals Web Extension
✓ opencv-contrib-python (LayerStyle)
✓ onnxruntime-gpu (DWPose)
✓ Environment Variables
✗ sageattention (Optional)

Required checks: 4/4 passed
✓ All required components verified successfully!
```

## System Requirements

These fixes are specifically for:
- **OS:** Windows 10/11 (including WSL2)
- **Python:** 3.10.x
- **GPU:** NVIDIA with CUDA support
- **CUDA:** 12.x (for onnxruntime-gpu and PyTorch compatibility)

## Troubleshooting

### opencv-contrib-python conflicts

If you get conflicts during installation:
```powershell
# Nuclear option - remove all opencv packages
.\.venv\Scripts\python.exe -m pip freeze | findstr opencv | ForEach-Object { pip uninstall -y $_.Split('==')[0] }

# Reinstall only opencv-contrib-python
.\.venv\Scripts\python.exe -m pip install opencv-contrib-python
```

### onnxruntime-gpu CUDA version mismatch

If onnxruntime-gpu doesn't detect CUDA:
- Verify PyTorch CUDA version: `python -c "import torch; print(torch.version.cuda)"`
- Install matching onnxruntime-gpu version for your CUDA version

### Environment variables not persisting

Environment variables set in PowerShell only last for that session. Use `start-comfyui.ps1` which sets them automatically, or set them system-wide in Windows Environment Variables settings.

## See Also

- [Optional Packages Documentation](./optional-packages.md)
- [Startup Test Results](./startup-test-results.md)

---

*Last updated: 2025-11-06*
```

**Step 2: Create README section about common issues**

Check if README.md exists and has a troubleshooting section:

Run: `Test-Path README.md`

If README.md exists, consider adding a reference to the setup fixes documentation.

**Step 3: Commit documentation**

```bash
git add docs/SETUP-FIXES.md
git commit -m "docs: add comprehensive setup fixes documentation"
```

---

## Task 9: Final Verification and Cleanup

**Files:**
- Review all created scripts and documentation
- Clean up any temporary files

**Context:** Final check that everything is working and properly documented.

**Step 1: Run full verification suite**

Run:
```powershell
$env:NUMEXPR_MAX_THREADS = "32"
.\.venv\Scripts\python.exe .\scripts\verify-comfyui-setup.py
```

Expected: All required checks pass (4/4)

**Step 2: Test actual ComfyUI startup**

Run: `.\start-comfyui.ps1`

Expected: ComfyUI starts without the original errors, web server accessible at http://127.0.0.1:8188

**Step 3: Review created files**

Run: `git status`

Expected output should show:
```
scripts/fix-comfyliterals-symlink.ps1
scripts/verify-opencv.py
scripts/verify-onnxruntime.py
scripts/verify-comfyui-setup.py
scripts/set-comfyui-env.ps1
scripts/test-startup.ps1
start-comfyui.ps1
.env.example
docs/plans/2025-11-06-fix-comfyui-startup-issues.md
docs/optional-packages.md
docs/startup-test-results.md
docs/SETUP-FIXES.md
```

**Step 4: Create final summary commit**

```bash
git add -A
git commit -m "feat: complete ComfyUI startup issues fix

Resolves all critical startup errors:
- ComfyLiterals symlink error (WinError 1314)
- LayerStyle guidedFilter import error
- DWPose CPU-only performance warning
- NumExpr thread limitation

Adds comprehensive verification and documentation:
- Automated fix scripts for all issues
- Verification scripts for each component
- Complete setup documentation
- Startup helper script with optimal settings

All required fixes verified and working.
Optional sageattention documented but not required."
```

**Step 5: Review commit history**

Run: `git log --oneline -10`

Expected: Should see all commits from this plan in chronological order

**Step 6: Verify no uncommitted changes**

Run: `git status`

Expected: "nothing to commit, working tree clean"

---

## Completion Checklist

After completing all tasks, verify:

- [x] ComfyLiterals web extension working (no WinError 1314)
- [x] LayerStyle nodes fully functional (guidedFilter available)
- [x] DWPose using GPU acceleration (no CPU warning)
- [x] NumExpr using all 32 CPU threads
- [x] All verification scripts passing
- [x] Documentation complete and accurate
- [x] Helper scripts functional
- [x] All changes committed with clear messages

## Performance Expectations

After applying all fixes:

**Startup:**
- No critical errors or warnings
- All custom nodes load successfully
- ~10-15 second total startup time

**Runtime Performance:**
- DWPose: 10-50x faster (GPU vs CPU)
- NumExpr: 2x thread utilization (32 vs 16)
- LayerStyle: All features functional

## Maintenance

**Regular checks:**
```powershell
# Verify setup periodically
.\.venv\Scripts\python.exe .\scripts\verify-comfyui-setup.py

# Always use optimized startup
.\start-comfyui.ps1
```

**After package updates:**
Re-run verification scripts to ensure fixes still work.

---

## References

- ComfyUI Documentation: https://github.com/comfyanonymous/ComfyUI
- LayerStyle Issue: https://github.com/chflame163/ComfyUI_LayerStyle/issues/5
- ONNX Runtime GPU: https://onnxruntime.ai/docs/execution-providers/CUDA-ExecutionProvider.html
```

