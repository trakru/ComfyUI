# ComfyUI startup script with optimal environment configuration

# Set environment variables
& "$PSScriptRoot\scripts\set-comfyui-env.ps1"

# Activate virtual environment and start ComfyUI
Write-Host "`nStarting ComfyUI..." -ForegroundColor Cyan
& ".venv\Scripts\Activate.ps1"
python main.py
