<#
.SYNOPSIS
  Searches known install paths for Teams’ Squirrel updater and triggers an update.

.DESCRIPTION
  Teams’ per-user client includes Update.exe under %LocalAppData%\Microsoft\Teams.
  Preview/dev channels and machine-wide installs live in variant folders.
  This script iterates through those paths, starts each updater found,
  and reports any successes or failures.
#>

# Known Squirrel update executable locations
$updaterPaths = @(
  # Per-user stable channel
  "$env:LOCALAPPDATA\Microsoft\Teams\Update.exe",
  # Per-user preview/dev channel
  "$env:LOCALAPPDATA\Microsoft\Teams Dev\Update.exe",
  # Machine-wide installer loader (may proxy to per-user installs)
  "$env:ProgramFiles(x86)\Teams Installer\Update.exe"
)

$didTrigger = $false

foreach ($path in $updaterPaths) {
    if (Test-Path -LiteralPath $path) {
        try {
            Start-Process -FilePath $path `
                          -ArgumentList '--processStart','Teams.exe' `
                          -NoNewWindow -ErrorAction Stop

            Write-Output "✅ Triggered updater at:`n$path"
            $didTrigger = $true
        }
        catch {
            Write-Warning "⚠ Failed to launch updater at:`n$path`n$_"
        }
    }
}

if (-not $didTrigger) {
    Write-Warning "No Teams updater executable found in any of the known locations."
    Write-Output "Checked paths:`n$($updaterPaths -join "`n")"
}

