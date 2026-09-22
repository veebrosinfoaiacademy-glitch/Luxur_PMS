# Downloads the pinned PocketBase binary for local development (Windows).
# Run from the repo root: powershell -File scripts/setup_pocketbase.ps1

$ErrorActionPreference = "Stop"
$Version = "0.40.4"
$Dest = Join-Path $PSScriptRoot "..\pocketbase"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Dest "pb_migrations") | Out-Null

$arch = if ([System.Environment]::Is64BitOperatingSystem) { "amd64" } else { "arm64" }
$zipName = "pocketbase_${Version}_windows_${arch}.zip"
$url = "https://github.com/pocketbase/pocketbase/releases/download/v$Version/$zipName"
$zipPath = Join-Path $Dest $zipName

Write-Host "Downloading PocketBase v$Version ($arch) ..."
Invoke-WebRequest -Uri $url -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $Dest -Force
Remove-Item $zipPath

Write-Host "PocketBase binary ready at $Dest\pocketbase.exe"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  cd pocketbase"
Write-Host "  .\pocketbase.exe serve          # applies pb_migrations automatically"
Write-Host "  .\pocketbase.exe superuser upsert you@local.test YourPassword123!"
Write-Host "  node ..\scripts\seed_dev_data.mjs"
