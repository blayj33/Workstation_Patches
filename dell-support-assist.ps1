<#
.SYNOPSIS
  Silently upgrades Dell SupportAssist Business to the latest version.

.DESCRIPTION
  - Checks the file version of SupportAssist.exe
  - Downloads the current installer from Dell
  - Runs a silent install to upgrade
  - Deletes the installer and reports the new version

.NOTES
  Requires Administrator rights.
#>

# Ensure script is running elevated
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Error "Please run this script as Administrator."
  Exit 1
}

# Configuration
$exePath     = "C:\Program Files\Dell\SupportAssistAgent\bin\SupportAssist.exe"
$downloadUrl = "https://downloads.dell.com/serviceability/catalog/SupportAssistBusinessInstaller.exe"
$tempInstaller = Join-Path $env:TEMP "SupportAssistBusinessInstaller.exe"
$minVersion  = [Version]"4.9.0.0"

# Get current installed version (or 0.0.0.0 if not found)
if (Test-Path $exePath) {
  $currentVersion = [Version]((Get-Item $exePath).VersionInfo.ProductVersion)
} else {
  Write-Output "SupportAssist not found; assuming version 0.0.0.0"
  $currentVersion = [Version]"0.0.0.0"
}

Write-Output "Installed SupportAssist version: $currentVersion"

# Only upgrade if current < minimum required
if ($currentVersion -lt $minVersion) {
  
  Write-Output "Downloading latest SupportAssist installer..."
  Invoke-WebRequest -Uri $downloadUrl -OutFile $tempInstaller -UseBasicParsing

  Write-Output "Running silent upgrade..."
  # /s for the wrapper, /v"/qn REBOOT=Suppress" for MSI inside
  Start-Process -FilePath $tempInstaller `
    -ArgumentList '/s','/v"/qn REBOOT=Suppress"' `
    -Wait -NoNewWindow

  Write-Output "Cleaning up installer..."
  Remove-Item -Path $tempInstaller -Force

  # Verify new version
  if (Test-Path $exePath) {
    $newVersion = [Version]((Get-Item $exePath).VersionInfo.ProductVersion)
    Write-Output "Upgrade complete. New version: $newVersion"
  } else {
    Write-Warning "SupportAssist executable not found after install."
  }

} else {
  Write-Output "No upgrade needed. Installed version meets or exceeds $minVersion."
}
