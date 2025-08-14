#!ps
#maxlength=500000
#timeout=900000
<#
.SYNOPSIS
  Stops ForeScout SecureConnector and force-removes its install directory.

.DESCRIPTION
  1. Verifies Administrator rights  
  2. Locates the install directory under Program Files  
  3. Stops the “SecureConnector” service (if present)  
  4. Kills any SecureConnector.exe processes by path  
  5. Takes ownership and grants full control to BUILTIN\Administrators  
  6. Attempts a recursive, forced Remove-Item  
  7. If initial removal fails, schedules each file for deletion on reboot  
#>

# 1. Ensure we’re running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent() `
     ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

# 2. Define and verify the install path
$installPath = Join-Path $env:ProgramFiles 'ForeScout SecureConnector'
if (-not (Test-Path $installPath -PathType Container)) {
    Write-Host "Directory not found: $installPath"
    exit 0
}

Write-Host "Directory found: $installPath`n"

# 3. Stop the SecureConnector service (if it exists)
$svc = Get-Service -Name 'SecureConnector' -ErrorAction SilentlyContinue
if ($svc) {
    if ($svc.Status -eq 'Running') {
        Write-Host "Stopping service 'SecureConnector'..."
        Stop-Service -Name SecureConnector -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }
    else {
        Write-Host "Service 'SecureConnector' is not running."
    }
}
else {
    Write-Host "Service 'SecureConnector' not found."
}

# 4. Kill any processes whose executable lives under the install path
Write-Host "`nSearching for running executables in $installPath..."
Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        if ($_.Path -and $_.Path.StartsWith($installPath, 'InvariantCultureIgnoreCase')) {
            Write-Host "  - Killing $($_.ProcessName) (PID $($_.Id))"
            Stop-Process -Id $_.Id -Force -ErrorAction Stop
        }
    } catch {
        # ignore processes without a Path property
    }
}

# 5. Take ownership and grant Administrators full control
Write-Host "`nAdjusting permissions on $installPath..."
$quoted = '"' + $installPath + '"'
Start-Process -FilePath takeown -ArgumentList "/F $quoted /R /D Y" -NoNewWindow -Wait
Start-Process -FilePath icacls -ArgumentList "$quoted /grant `"BUILTIN\Administrators`":(OI)(CI)F /T /C" `
              -NoNewWindow -Wait

# 6. Attempt to remove the directory
Write-Host "`nAttempting to remove directory..."
try {
    Remove-Item -Path $installPath -Recurse -Force -ErrorAction Stop
    Write-Host "`nSuccessfully removed: $installPath"
    exit 0
}
catch {
    Write-Warning "`nInitial removal failed: $_"
}

# 7. Schedule pending file rename operations on reboot
Write-Host "`nScheduling files for deletion on next reboot..."
$pending = @()

Get-ChildItem -Path $installPath -Recurse -Force | ForEach-Object {
    # Queue each file and the directory itself
    $fullPath = $_.FullName
    $pending += $fullPath
    if ($_.PSIsContainer) {
        # Append a trailing slash for directories
        $pending[-1] = $fullPath + '\'
    }
}

if ($pending.Count -eq 0) {
    Write-Warning "Nothing queued for deletion. Please check permissions or locks manually."
    exit 2
}

# Write the PendingFileRenameOperations registry value (MultiString)
try {
    New-ItemProperty `
      -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' `
      -Name PendingFileRenameOperations `
      -PropertyType MultiString `
      -Value $pending `
      -Force | Out-Null

    Write-Host "`nAll items queued. Reboot the machine to complete removal."
    exit 0
}
catch {
    Write-Error "Failed to schedule reboot-time deletion: $_"
    exit 2
}
