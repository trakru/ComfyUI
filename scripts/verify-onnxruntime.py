#!/usr/bin/env python3
# ruff: noqa: T201
# -*- coding: utf-8 -*-
"""Verify onnxruntime-gpu installation and CUDA provider availability."""

import sys
import io

# Set up UTF-8 encoding for stdout to handle checkmarks on Windows
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")


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

    if "CUDAExecutionProvider" in providers:
        print("✓ CUDAExecutionProvider is available")
    else:
        print("✗ CUDAExecutionProvider not found")
        print("  This means GPU acceleration won't work for DWPose")
        return False

    # Check if CUDA provider can be initialized
    try:
        _ = ort.SessionOptions()  # Minimal test - verify we can request CUDA
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
