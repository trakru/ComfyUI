# ComfyUI startup script with optimal environment configuration

# Set environment variables
& "$PSScriptRoot\scripts\set-comfyui-env.ps1"

# Activate virtual environment and start ComfyUI
Write-Host "`nStarting ComfyUI..." -ForegroundColor Cyan
& ".venv\Scripts\Activate.ps1"
# python main.py --output-directory "\\R-home\f\repos_\insightful\models\comfy-outputs"

python main.py
