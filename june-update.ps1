
<#
.SYNOPSIS
  Provides four methods to trigger June 2025 Office RCE patches with clear “begin”/“finish” messages.
.NOTES
  - Run as Administrator.
  - Does not use winget.
#>

# Ensure script runs elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  throw "Please re-run this script as Administrator."
}


function Invoke-OfficeWindowsUpdate {
  Write-Output "=== [Windows Update] Begin Office patch scan/download/install ==="
  Write-Output "[Windows Update] Scanning for Office updates..."
  UsoClient StartScan       | Out-Null
  Start-Sleep 2

  Write-Output "[Windows Update] Downloading updates..."
  UsoClient StartDownload   | Out-Null
  Start-Sleep 2

  Write-Output "[Windows Update] Installing updates..."
  UsoClient StartInstall    | Out-Null
  Start-Sleep 2

  Write-Output "=== [Windows Update] Finished Office patching ==="
}


function Invoke-OfficeCOMUpdate {
  Write-Output "=== [COM API] Begin Office update via Microsoft.Update.Session ==="
  $session  = New-Object -ComObject Microsoft.Update.Session
  $searcher = $session.CreateUpdateSearcher()
  $result   = $searcher.Search("Type='Software' AND IsInstalled=0 AND Title LIKE '%Office%'")

  if ($result.Updates.Count -eq 0) {
    Write-Output "[COM API] No pending Office updates found."
  }
  else {
    Write-Output "[COM API] Found $($result.Updates.Count) update(s); downloading..."
    $coll = New-Object -ComObject Microsoft.Update.UpdateColl
    foreach ($u in $result.Updates) { $coll.Add($u) | Out-Null }

    $downloader = $session.CreateUpdateDownloader()
    $downloader.Updates = $coll
    $downloader.Download()

    Write-Output "[COM API] Installing downloaded update(s)..."
    $installer = $session.CreateUpdateInstaller()
    $installer.Updates = $coll
    $installer.Install() | Out-Null

    Write-Output "=== [COM API] Finished Office patching ==="
  }
}


function Invoke-ClickToRunUpdate {
  Write-Output "=== [Click-to-Run] Begin in-app Office update ==="
  $c2r = "$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
  if (-not (Test-Path $c2r)) {
    Write-Warning "[Click-to-Run] OfficeC2RClient.exe not found. Skipping."
  }
  else {
    Write-Output "[Click-to-Run] Launching OfficeC2RClient.exe /update user..."
    Start-Process $c2r -ArgumentList "/update user" -Wait -NoNewWindow
    Write-Output "=== [Click-to-Run] Finished in-app Office update ==="
  }
}


function Invoke-OfficeMsuUpdate {
  param(
    [Parameter(Mandatory)]
    [string] $MsuPath
  )
  Write-Output "=== [MSU] Begin installing $MsuPath ==="
  if (-not (Test-Path $MsuPath)) {
    throw "[MSU] File not found: $MsuPath"
  }

  Write-Output "[MSU] Installing via wusa.exe /quiet /norestart..."
  Start-Process wusa.exe -ArgumentList "`"$MsuPath`" /quiet /norestart" -Wait -NoNewWindow

  Write-Output "=== [MSU] Finished installing $MsuPath ==="
}


<#
.EXAMPLE
  # Run Windows Update method
  Invoke-OfficeWindowsUpdate

  # Run COM API method
  Invoke-OfficeCOMUpdate

  # Run Click-to-Run method
  Invoke-ClickToRunUpdate

  # Run MSU method (point to your .msu file or UNC path)
  Invoke-OfficeMsuUpdate -MsuPath "\\fileserver\OfficePatches\KB5002616.msu"
#>
