# Concise detection for CVE-2025-53783 (Teams < 25122.1415.3698.6812)
$min = [version]'25122.1415.3698.6812'

# Gather all candidate Teams executables
$exePaths = @(
  # MSIX under WindowsApps
  Get-ChildItem 'C:\Program Files\WindowsApps' -Directory -ErrorAction SilentlyContinue |
    Where-Object Name -Like 'MSTeams_*_x64__8wekyb3d8bbwe' |
    ForEach-Object { Join-Path $_.FullName 'ms-teams.exe' }

  # Per-user Squirrel installs
  "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe",
  "$env:LOCALAPPDATA\Microsoft\Teams Dev\current\Teams.exe"

  # Machine-wide installer
  "${env:ProgramFiles(x86)}\Teams Installer\Teams.exe",
  "$env:ProgramFiles\Teams Installer\Teams.exe"
) | Where-Object { Test-Path $_ } | Sort-Object -Unique

if (-not $exePaths) {
  Write-Output 'No Teams installs found.'
  return
}

# Version check
$exePaths | ForEach-Object {
  $v = [version](Get-Item $_).VersionInfo.FileVersion
  "{0} → {1}" -f $_, (if ($v -lt $min) { "[VULNERABLE]" } else { "[SAFE]" }) + " $v"
}
