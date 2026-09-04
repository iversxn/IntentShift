param(
  [string]$Version = '1.0.0'
)

$ErrorActionPreference = 'Stop'
$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$AppSource = Join-Path $RepositoryRoot 'apps\lua\IntentShift'
$Distribution = Join-Path $RepositoryRoot 'dist'
$StagingRoot = Join-Path $Distribution 'stage'
$PackageRoot = Join-Path $StagingRoot 'IntentShift'
$PackageApp = Join-Path $PackageRoot 'apps\lua\IntentShift'
$Archive = Join-Path $Distribution "IntentShift-v$Version.zip"

if (Test-Path -LiteralPath $StagingRoot) {
  Remove-Item -LiteralPath $StagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $PackageApp -Force | Out-Null
Copy-Item -Path (Join-Path $AppSource '*') -Destination $PackageApp -Recurse -Force
Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'README.md') -Destination $PackageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'LICENSE') -Destination $PackageRoot
$PackageAssets = Join-Path $PackageRoot 'assets'
New-Item -ItemType Directory -Path $PackageAssets -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'assets\intent-shift-cover.png') -Destination $PackageAssets

if (Test-Path -LiteralPath $Archive) {
  Remove-Item -LiteralPath $Archive -Force
}
Compress-Archive -Path $PackageRoot -DestinationPath $Archive -CompressionLevel Optimal
Remove-Item -LiteralPath $StagingRoot -Recurse -Force

$Hash = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash
Write-Output "Built: $Archive"
Write-Output "SHA256: $Hash"
