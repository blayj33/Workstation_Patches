# Path to msedge.exe
$Edge = "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe"

# 1. Windows Update trigger (requires “Receive updates for other Microsoft products”)
function Invoke-WindowsUpdate {
    Write-Host "Scanning for Microsoft updates…"
    UsoClient StartScan | Out-Null
    Start-Sleep 5
    Write-Host "Downloading updates…"
    UsoClient StartDownload | Out-Null
    Start-Sleep 5
    Write-Host "Installing updates…"
    UsoClient StartInstall | Out-Null
}

# 2. In-app update via About page
function Invoke-InAppUpdate {
    Write-Host "Opening Edge About page to force in-place update…"
    Start-Process $Edge -ArgumentList "edge://settings/help"
}

# 3. winget upgrade
function Invoke-WingetUpdate {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Updating via winget…"
        winget upgrade --id Microsoft.Edge --silent
    } else {
        Write-Warning "winget not installed; skipping"
    }
}

# --- Execute selected methods ---
Invoke-WindowsUpdate
Invoke-InAppUpdate
Invoke-WingetUpdate
