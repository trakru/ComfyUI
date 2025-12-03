#!/usr/bin/env python3
# ruff: noqa: T201
"""Verify opencv-contrib-python installation and guidedFilter availability."""

import sys


def verify_opencv():
    """Check if opencv-contrib-python is properly installed."""
    print("Verifying opencv-contrib-python installation...")

    try:
        import cv2

        # Try to get version, but don't fail if not available
        try:
            version = cv2.__version__
        except AttributeError:
            version = "unknown (module may be corrupted)"
        print(f"[OK] OpenCV imported, version: {version}")
    except ImportError as e:
        print(f"[FAIL] Failed to import cv2: {e}")
        return False

    try:
        from cv2 import ximgproc

        print("[OK] cv2.ximgproc module imported successfully")
    except ImportError as e:
        print(f"[FAIL] Failed to import cv2.ximgproc: {e}")
        return False

    try:
        # Check if guidedFilter is available
        if hasattr(ximgproc, "guidedFilter"):
            print("[OK] guidedFilter function is available")
        else:
            print("[FAIL] guidedFilter function not found in ximgproc")
            return False
    except Exception as e:
        print(f"[FAIL] Error checking guidedFilter: {e}")
        return False

    print("\n[SUCCESS] All opencv-contrib-python components verified successfully!")
    return True


if __name__ == "__main__":
    success = verify_opencv()
    sys.exit(0 if success else 1)
