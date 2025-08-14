#!ps
#maxlength=500000
#timeout=900000
<#
.SYNOPSIS
  Deletes the Teams cache & application folder under every local user profile.

.DESCRIPTION
  Iterates through each folder in C:\Users, looks for
  AppData\Local\Microsoft\Teams, and removes it if present.

.NOTES
  Must be run with administrative privileges to delete other users’ folders.
#>

# Ensure script runs elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Warning "This script must be run as Administrator."
    exit 1
}

# Base path for user profiles
$usersRoot = Join-Path $env:SystemDrive 'Users'

# Walk each profile folder
Get-ChildItem -Path $usersRoot -Directory | ForEach-Object {
    $profileName = $_.Name
    $teamsFolder = Join-Path $_.FullName 'AppData\Local\Microsoft\Teams'

    if (Test-Path $teamsFolder) {
        try {
            Remove-Item -Path $teamsFolder -Recurse -Force -ErrorAction Stop
            Write-Output "Deleted Teams folder for user '$profileName': $teamsFolder"
        }
        catch {
            Write-Warning "Failed to delete Teams folder for user '$profileName': $_"
        }
    }
    else {
        Write-Output "No Teams folder found for user '$profileName'."
    }
}
