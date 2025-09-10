<#
.SYNOPSIS
  Detects Microsoft Teams installs older than 25122.1415.3698.6812 and uninstalls them.

.DESCRIPTION
  • MSIX (WindowsApps) 
  • Machine-wide MSI installer 
  • Per-user Squirrel installs
#>

# Minimum non-vulnerable build
$minSafe = [version]'25122.1415.3698.6812'

# 1. MSIX-based Teams under WindowsApps
Get-AppxPackage -AllUsers |
  Where-Object PackageFamilyName -Like 'MSTeams_*' |
  Where-Object { [version]$_.Version -lt $minSafe } |
  ForEach-Object {
    Write-Output "Removing MSIX Teams v$($_.Version) → $($_.PackageFullName)"
    Remove-AppxPackage     -Package  $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    # also remove the provisioned package for new users
    Start-Process dism.exe -ArgumentList @(
      '/Online',
      '/Remove-ProvisionedAppxPackage',
      "/PackageName:$($_.PackageName)"
    ) -NoNewWindow -Wait -ErrorAction SilentlyContinue
  }

# 2. Machine-wide MSI installer
Get-CimInstance -ClassName Win32_Product |
  Where-Object {
    $_.Name -eq 'Teams Machine-Wide Installer' -and
    [version]$_.Version -lt $minSafe
  } |
  ForEach-Object {
    Write-Output "Uninstalling MSI Teams Installer v$($_.Version)"
    Start-Process msiexec.exe -ArgumentList "/x",$_.IdentifyingNumber,"/qn" -Wait
  }

# 3. Per-user Squirrel installs
@(
  "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe",
  "$env:LOCALAPPDATA\Microsoft\Teams Dev\current\Teams.exe"
) |
Where-Object { Test-Path $_ } |
ForEach-Object {
  $ver = [version](Get-Item $_).VersionInfo.FileVersion
  if ($ver -lt $minSafe) {
    Write-Output "Removing Squirrel Teams v$ver at $_"
    Stop-Process -Name Teams -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Split-Path $_ -Parent) -Recurse -Force
  }
}
