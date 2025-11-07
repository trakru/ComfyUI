# Set optimal environment variables for ComfyUI on this system
# Run this before starting ComfyUI for best performance

Write-Host "Configuring ComfyUI environment variables..." -ForegroundColor Cyan

# NumExpr: Use all 32 CPU cores instead of default 16
$env:NUMEXPR_MAX_THREADS = "32"
Write-Host "[OK] Set NUMEXPR_MAX_THREADS=32 (detected 32 cores)" -ForegroundColor Green

# Display current environment
Write-Host "`nCurrent ComfyUI environment:" -ForegroundColor Cyan
Write-Host "  NUMEXPR_MAX_THREADS: $env:NUMEXPR_MAX_THREADS" -ForegroundColor White

Write-Host "`nEnvironment configured! Now run: python main.py" -ForegroundColor Green
