# Optional ComfyUI Packages

This document lists optional packages that can enhance ComfyUI performance but are not required for core functionality.

## sageattention

**Status:** Optional performance enhancement (Installation failed on this system)
**Purpose:** Advanced attention mechanism optimizations for certain models
**Impact:** May improve inference speed for compatible models

### Installation Status

**Tested on 2025-11-06:** Installation failed with build error.

Error details:
- Package requires `torch` module to be available during setup.py execution
- Build environment isolation prevents access to the installed PyTorch
- Error: `ModuleNotFoundError: No module named 'torch'` during wheel building

This is a known issue with packages that require torch at build time in isolated pip build environments.

### Installation Attempt

```bash
.venv\Scripts\python.exe -m pip install sageattention
```

### Compatibility

- Requires compatible PyTorch version
- Requires torch to be available during build process
- May not be available for all CUDA versions
- Check package documentation for system requirements

### Verification

If installed successfully, ComfyUI will automatically detect and use sageattention.
Check startup logs for: "sageattention package is installed"

### Troubleshooting

If installation fails with build errors:
- This package may require specific CUDA toolkit versions
- Build environment isolation may prevent access to already-installed torch
- It's optional - ComfyUI works fine without it
- **Recommendation: Skip this package if installation fails**

## Other Optional Packages

### TensorRT (Advanced)

For advanced users wanting maximum inference speed on NVIDIA GPUs.

**Not recommended unless you have specific TensorRT experience.**

---

*Last updated: 2025-11-06*
