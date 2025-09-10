<#
.SYNOPSIS
  Finds and runs any Teams update executable—Squirrel or MSIX—across all known install locations.

.DESCRIPTION
  Microsoft Teams update executables can reside in:
    • Per-user Squirrel installs:
        %LocalAppData%\Microsoft\Teams\Update.exe  
        %LocalAppData%\Microsoft\Teams Dev\Update.exe  
        %LocalAppData%\Microsoft\Teams\current\Update.exe  
    • Machine-wide Squirrel loader:
        %ProgramFiles(x86)%\Teams Installer\Update.exe  
        %ProgramFiles%\Teams Installer\Update.exe  
    • MSIX package under WindowsApps:
        C:\Program Files\WindowsApps\MSTeams_*_x64__8wekyb3d8bbwe\ms-teamsupdate.exe  
#>

# 1. Build list of potential updater paths
$updaterPaths = @(
  # Per-user Squirrel channels
  Join-Path $env:LOCALAPPDATA     'Microsoft\Teams\Update.exe'
  Join-Path $env:LOCALAPPDATA     'Microsoft\Teams Dev\Update.exe'
  Join-Path $env:LOCALAPPDATA     'Microsoft\Teams\current\Update.exe'

  # Machine-wide Squirrel installer
  Join-Path ${env:ProgramFiles(x86)} 'Teams Installer\Update.exe'
  Join-Path $env:ProgramFiles           'Teams Installer\Update.exe'
)

# 2. Scan WindowsApps for MSIX-based updater
$winAppsPath = 'C:\Program Files\WindowsApps'
if (Test-Path $winAppsPath) {
  Get-ChildItem -Path $winAppsPath -Directory `
    | Where-Object Name -Like 'MSTeams_*_x64__8wekyb3d8bbwe' `
    | ForEach-Object {
        $msixUpdater = Join-Path $_.FullName 'ms-teamsupdate.exe'
        $updaterPaths += $msixUpdater
    }
}

# 3. Attempt to launch each updater
$found = $false
foreach ($exe in $updaterPaths) {
  if (Test-Path -LiteralPath $exe) {
    try {
      Start-Process -FilePath $exe `
                    -ArgumentList '--silent' `
                    -NoNewWindow -ErrorAction Stop
      Write-Output "✅ Launched updater: $exe"
      $found = $true
    }
    catch {
      Write-Warning "⚠ Failed to run updater at $exe`n$_"
    }
  }
}

if (-not $found) {
  Write-Warning 'No Teams updater executable was found in any known location.'
  Write-Output "Checked paths:`n$($updaterPaths -join "`n")"
}

