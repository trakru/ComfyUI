#!/usr/bin/env python3
# ruff: noqa: T201
"""Comprehensive ComfyUI setup verification script."""

import sys
import os
from pathlib import Path


def print_header(text):
    """Print a formatted header."""
    print(f"\n{'=' * 60}")
    print(f"  {text}")
    print(f"{'=' * 60}\n")


def print_status(check_name, passed, message=""):
    """Print a status line for a check."""
    # Use ASCII characters for better Windows compatibility
    status = "[PASS]" if passed else "[FAIL]"
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

        if not hasattr(ximgproc, "guidedFilter"):
            return False, "guidedFilter not found in ximgproc"

        return True, f"OpenCV {cv2.__version__} with ximgproc.guidedFilter"
    except ImportError as e:
        return False, str(e)


def verify_onnxruntime():
    """Verify onnxruntime-gpu with CUDA support."""
    try:
        import onnxruntime as ort

        providers = ort.get_available_providers()
        has_cuda = "CUDAExecutionProvider" in providers

        if not has_cuda:
            return False, f"CUDA not available. Providers: {providers}"

        return True, f"Version {ort.__version__} with CUDA support"
    except ImportError as e:
        return False, str(e)


def verify_environment():
    """Verify environment variables are set correctly."""
    numexpr_threads = os.environ.get("NUMEXPR_MAX_THREADS", "NOT SET")

    if numexpr_threads == "NOT SET":
        return False, "NUMEXPR_MAX_THREADS not set (should be 32)"

    if numexpr_threads != "32":
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
    _ = results[4:]  # Last is optional (unused but kept for clarity)

    required_passed = sum(required_checks)
    required_total = len(required_checks)

    print(f"Required checks: {required_passed}/{required_total} passed")

    if all(required_checks):
        print("\n[PASS] All required components verified successfully!")
        print("  ComfyUI is ready to run with all fixes applied.")
        return 0
    else:
        print("\n[FAIL] Some required components failed verification.")
        print(
            "  Please review the failures above and re-run the appropriate fix tasks."
        )
        return 1


if __name__ == "__main__":
    sys.exit(main())
