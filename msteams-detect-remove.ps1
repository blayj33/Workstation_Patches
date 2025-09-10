<#
.SYNOPSIS
  Detects and uninstalls Microsoft Teams builds older than 25122.1415.3698.6812 (CVE-2025-53783).

.DESCRIPTION
  • Finds MSIX-installed Teams under WindowsApps and removes vulnerable packages.  
  • Removes the machine-wide MSI installer if it’s below the safe build.  
  • Cleans up per-user Squirrel installs in LocalAppData.  
#>

# Minimum non-vulnerable version
$minSafe = [version]'25122.1415.3698.6812'

# 1. Remove vulnerable MSIX packages (Store/WindowsApps)
Get-AppxPackage -AllUsers |
  Where-Object { 
    $_.PackageFamilyName -eq 'MSTeams_8wekyb3d8bbwe' -and 
    [version]$_.Version -lt $minSafe 
  } |
  ForEach-Object {
    Write-Output "Removing MSIX Teams: $($_.PackageFullName) v$($_.Version)"
    Remove-AppxPackage           -Package   $_.PackageFullName -AllUsers
    Remove-AppxProvisionedPackage -Online   -PackageName $_.PackageName
  }

# 2. Remove vulnerable machine-wide MSI installer
Get-WmiObject -Class Win32_Product |
  Where-Object { 
    $_.Name   -eq 'Teams Machine-Wide Installer' -and 
    [version]$_.Version -lt $minSafe 
  } |
  ForEach-Object {
    Write-Output "Uninstalling MSI Installer v$($_.Version)"
    Start-Process msiexec.exe -ArgumentList "/x",$_.IdentifyingNumber,"/qn" -Wait
  }

# 3. Remove vulnerable per-user Squirrel installations
$paths = @(
  "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe",
  "$env:LOCALAPPDATA\Microsoft\Teams Dev\current\Teams.exe"
) | Where-Object { Test-Path $_ }

foreach ($exe in $paths) {
  $ver = [version](Get-Item $exe).VersionInfo.FileVersion
  if ($ver -lt $minSafe) {
    Write-Output "Removing Squirrel Teams v$ver at $exe"
    Stop-Process -Name Teams -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Split-Path $exe -Parent) -Recurse -Force
  }
}

