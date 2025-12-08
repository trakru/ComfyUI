# Fix ComfyLiterals symlink issue by copying files
$Source = "D:\repos\ComfyUI\custom_nodes\ComfyLiterals\js"
$Target = "D:\repos\ComfyUI\web\extensions\ComfyLiterals"

Write-Host "Fixing ComfyLiterals web extension..." -ForegroundColor Cyan

# Remove existing target if it exists
if (Test-Path $Target) {
    Write-Host "Removing existing target directory..." -ForegroundColor Yellow
    Remove-Item -Path $Target -Recurse -Force
}

# Create parent directory if needed
$ParentDir = Split-Path -Parent $Target
if (-not (Test-Path $ParentDir)) {
    Write-Host "Creating parent directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
}

# Copy files
Write-Host "Copying files from $Source to $Target..." -ForegroundColor Yellow
Copy-Item -Path $Source -Destination $Target -Recurse -Force

if (Test-Path $Target) {
    Write-Host "Success! ComfyLiterals web extension installed." -ForegroundColor Green
} else {
    Write-Host "Error: Failed to copy files." -ForegroundColor Red
    exit 1
}
