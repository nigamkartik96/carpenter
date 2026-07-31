## Build the carpenter mobile APK and publish a GitHub release.
## Usage:  .\deploy-app.ps1            (auto-reads version from pubspec)
##         .\deploy-app.ps1 -SkipBuild (re-upload existing APK)

param([switch]$SkipBuild)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$app  = Join-Path $root 'carpenter_app'
$apk  = Join-Path $app  'build\app\outputs\flutter-apk\app-release.apk'

# Read version from pubspec
$pubspec = Get-Content (Join-Path $app 'pubspec.yaml') -Raw
if ($pubspec -match 'version:\s*(\S+)') { $version = $Matches[1] } else { throw 'Could not read version from pubspec.yaml' }
$tag = "v$($version -replace '\+.*','')"
Write-Host "`n=== Carpenter App Deploy — $version (tag $tag) ===" -ForegroundColor Cyan

# Build
if (-not $SkipBuild) {
    Write-Host "`n>> flutter pub get" -ForegroundColor Yellow
    Push-Location $app
    flutter pub get
    Write-Host "`n>> flutter build apk --release" -ForegroundColor Yellow
    flutter build apk --release
    Pop-Location
} else {
    Write-Host "`n>> Skipping build (using existing APK)" -ForegroundColor Yellow
}

if (-not (Test-Path $apk)) { throw "APK not found at $apk" }

# Delete existing release with same tag (if any)
Write-Host "`n>> Publishing GitHub release $tag" -ForegroundColor Yellow
Push-Location $root
try { gh release delete $tag --yes 2>$null } catch {}
gh release create $tag "${apk}#CarpenterHub-${tag}.apk" --title "$tag" --notes "Release $version"
Pop-Location

Write-Host "`n=== Done — APK published at tag $tag ===" -ForegroundColor Green

