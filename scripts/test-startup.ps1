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
