<#
.SYNOPSIS
  Detect Microsoft Teams RCE vulnerability CVE-2025-53783 by version.

.DESCRIPTION
  Teams desktop installs in several locations:
    • MSIX under WindowsApps (ms-teams.exe)
    • Per-user Squirrel client (Teams.exe)
    • Machine-wide installer (Teams.exe)
  This script locates each, reads its version, and reports vulnerability status.
#>

# Define the minimum safe version
$minSafeVersion = [version]"25122.1415.3698.6812"

# Collect potential Teams executables
$exePaths = @()

# 1. MSIX-based install under WindowsApps
$winAppsRoot = 'C:\Program Files\WindowsApps'
if (Test-Path $winAppsRoot) {
  $exePaths += Get-ChildItem -Path $winAppsRoot -Directory `
    | Where-Object Name -Like 'MSTeams_*_x64__8wekyb3d8bbwe' `
    | ForEach-Object { Join-Path $_.FullName 'ms-teams.exe' }
}

# 2. Per-user Squirrel installs
$exePaths += @(
  Join-Path $env:LOCALAPPDATA 'Microsoft\Teams\current\Teams.exe',
  Join-Path $env:LOCALAPPDATA 'Microsoft\Teams Dev\current\Teams.exe'
)

# 3. Machine-wide installer paths
$exePaths += @(
  Join-Path ${env:ProgramFiles(x86)} 'Teams Installer\Teams.exe',
  Join-Path $env:ProgramFiles           'Teams Installer\Teams.exe'
)

# Filter to existing files
$exePaths = $exePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -Unique

if (-not $exePaths) {
    Write-Output "No Teams executables found in known locations."
    return
}

# Check each version
foreach ($path in $exePaths) {
    $fileVersion = (Get-Item $path).VersionInfo.FileVersion
    $versionObj  = [version]$fileVersion

    if ($versionObj -lt $minSafeVersion) {
        Write-Output ("[VULNERABLE] {0} → version {1}" -f $path, $fileVersion)
    }
    else {
        Write-Output ("[SAFE]       {0} → version {1}" -f $path, $fileVersion)
    }
}
