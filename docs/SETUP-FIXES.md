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
