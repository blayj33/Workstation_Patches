<#
.SYNOPSIS
  Detects Microsoft Teams builds older than 25122.1415.3698.6812 and uninstalls them.
#>

$minSafe = [version]'25122.1415.3698.6812'

# 1. Gather all known Teams executable paths
$paths = @(
  # MSIX under WindowsApps
  Get-ChildItem 'C:\Program Files\WindowsApps' -Directory -ErrorAction SilentlyContinue |
    Where-Object Name -Like 'MSTeams_*_x64__8wekyb3d8bbwe' |
    ForEach-Object { Join-Path $_.FullName 'ms-teams.exe' }

  # Per-user Squirrel installs
  "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
  "$env:LOCALAPPDATA\Microsoft\Teams Dev\current\Teams.exe"

  # Machine-wide installer
  "${env:ProgramFiles(x86)}\Teams Installer\Teams.exe"
  "$env:ProgramFiles\Teams Installer\Teams.exe"
) |
Where-Object { Test-Path $_ } |
Sort-Object -Unique

if (-not $paths) {
  Write-Output 'No Teams installs found.'
  return
}

# 2. Check version and uninstall if vulnerable
$paths | ForEach-Object {
  $exe = $_
  $ver = [version](Get-Item $exe).VersionInfo.FileVersion

  if ($ver -lt $minSafe) {
    Write-Output "VULNERABLE $exe ($ver) → Uninstalling…"

    # MSIX package
    if ($exe -like '*WindowsApps*') {
      Get-AppxPackage -Name 'MSTeams*' -AllUsers |
        Where-Object { [version]$_.Version -eq $ver } |
        ForEach-Object {
          Remove-AppxPackage        -Package $_.PackageFullName               -ErrorAction SilentlyContinue
          Remove-AppxProvisionedPackage -Online -PackageName $_.PackageFullName -ErrorAction SilentlyContinue
        }
    }
    # Machine-wide MSI installer
    elseif ($exe -like '*\Teams Installer\Teams.exe') {
      $unstr = (Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' |
                Where-Object DisplayName -eq 'Teams Machine-Wide Installer').UninstallString
      if ($unstr) {
        Start-Process cmd -ArgumentList "/c $unstr /qn" -Wait -NoNewWindow
      }
    }
    # Per-user Squirrel install
    else {
      Stop-Process -Name Teams -ErrorAction SilentlyContinue
      Remove-Item -LiteralPath (Split-Path $exe -Parent) -Recurse -Force
    }
  }
  else {
    Write-Output "SAFE       $exe ($ver)"
  }
}

