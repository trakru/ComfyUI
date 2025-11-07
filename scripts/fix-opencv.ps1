# Fix opencv-contrib-python installation
# This script removes corrupted opencv packages and reinstalls opencv-contrib-python

Write-Host "Fixing opencv-contrib-python installation..." -ForegroundColor Cyan

$venvPath = "D:\repos\ComfyUI\.venv"
$pythonExe = "$venvPath\Scripts\python.exe"
$cv2Path = "$venvPath\lib\site-packages\cv2"

# Step 1: Check current installation
Write-Host "`n[1/4] Checking current opencv installation..." -ForegroundColor Yellow
& $pythonExe -m pip list | Select-String opencv

# Step 2: Remove cv2 directory manually (to fix corrupted state)
Write-Host "`n[2/4] Removing cv2 directory..." -ForegroundColor Yellow
if (Test-Path $cv2Path) {
    Remove-Item -Path $cv2Path -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "      [OK] Removed $cv2Path" -ForegroundColor Green
} else {
    Write-Host "      - cv2 directory not found" -ForegroundColor Gray
}

# Step 3: Uninstall all opencv packages
Write-Host "`n[3/4] Uninstalling opencv packages..." -ForegroundColor Yellow
& $pythonExe -m pip uninstall -y opencv-python opencv-contrib-python opencv-python-headless 2>&1 | Out-Null
Write-Host "      [OK] Uninstalled opencv packages" -ForegroundColor Green

# Step 4: Install opencv-contrib-python
Write-Host "`n[4/4] Installing opencv-contrib-python..." -ForegroundColor Yellow
& $pythonExe -m pip install opencv-contrib-python
if ($LASTEXITCODE -eq 0) {
    Write-Host "      [OK] Successfully installed opencv-contrib-python" -ForegroundColor Green
} else {
    Write-Host "      [FAIL] Failed to install opencv-contrib-python" -ForegroundColor Red
    exit 1
}

Write-Host "`nDone! Run verify-opencv.py to confirm the installation." -ForegroundColor Cyan
