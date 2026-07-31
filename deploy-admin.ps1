## Build the admin console (Flutter web) and deploy to Firebase Hosting.
## Usage:  .\deploy-admin.ps1            (build + deploy hosting + indexes)
##         .\deploy-admin.ps1 -SkipBuild (deploy existing build folder)

param([switch]$SkipBuild)

$ErrorActionPreference = 'Stop'
$root  = Split-Path -Parent $MyInvocation.MyCommand.Path
$admin = Join-Path $root 'admin_console'
$web   = Join-Path $admin 'build\web'

Write-Host "`n=== Admin Console Deploy ===" -ForegroundColor Cyan

# Build
if (-not $SkipBuild) {
    Write-Host "`n>> flutter pub get" -ForegroundColor Yellow
    Push-Location $admin
    flutter pub get
    Write-Host "`n>> flutter build web --release" -ForegroundColor Yellow
    flutter build web --release
    Pop-Location
} else {
    Write-Host "`n>> Skipping build (using existing build/web)" -ForegroundColor Yellow
}

if (-not (Test-Path $web)) { throw "build/web not found at $web" }

# Deploy hosting + Firestore indexes
Write-Host "`n>> Deploying to Firebase Hosting + Firestore indexes" -ForegroundColor Yellow
Push-Location $admin
npx firebase-tools deploy --only hosting,firestore:indexes
Pop-Location

Write-Host "`n=== Done — https://carpenterhub-96958.web.app ===" -ForegroundColor Green

