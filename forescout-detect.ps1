#!ps
#maxlength=500000
#timeout=900000
<#
.SYNOPSIS
  Detects ForeScout SecureConnector installation.

.DESCRIPTION
  Checks for SecureConnector.exe in Program Files,
  validates Start Menu folder, queries registry uninstall keys,
  and inspects Win32_Product via WMI/CIM.

.EXAMPLE
  .\Check-ForeScoutSecureConnector.ps1
#>

[CmdletBinding()]
param()

function Test-Executable {
    param([string]$Path)
    if (Test-Path $Path) {
        Write-Host "Found executable at $Path" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Executable not found at $Path" -ForegroundColor Yellow
        return $false
    }
}

function Test-StartMenu {
    param([string]$Path)
    if (Test-Path $Path) {
        Write-Host "Start Menu folder found at $Path" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Start Menu folder not found at $Path" -ForegroundColor Yellow
        return $false
    }
}

function Test-Registry {
    $found = $false
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($key in $keys) {
        Get-ItemProperty -Path $key -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -match 'ForeScout SecureConnector' } |
            ForEach-Object {
                Write-Host "Registry entry found: $($_.DisplayName)" -ForegroundColor Green
                $found = $true
            }
    }

    if (-not $found) {
        Write-Host "No matching registry uninstall entries found" -ForegroundColor Yellow
    }

    return $found
}

function Test-WmiProduct {
    try {
        $products = Get-CimInstance -ClassName Win32_Product `
            -Filter "Name LIKE '%ForeScout SecureConnector%'" 2>$null

        if ($products) {
            foreach ($p in $products) {
                Write-Host "WMI product found: $($p.Name) v$($p.Version)" -ForegroundColor Green
            }
            return $true
        }
        else {
            Write-Host "No WMI products matching found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "WMI query failed: $_" -ForegroundColor Red
        return $false
    }
}

# Main logic
$exePath        = Join-Path $env:ProgramFiles 'ForeScoutSecureConnector\SecureConnector.exe'
$startMenuPath  = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\ForeScout SecureConnector'
$foundExe       = Test-Executable -Path $exePath
$foundStartMenu = Test-StartMenu  -Path $startMenuPath
$foundReg       = Test-Registry
$foundWmi       = Test-WmiProduct

Write-Host ''
if ($foundExe -or $foundStartMenu -or $foundReg -or $foundWmi) {
    Write-Host "ForeScout SecureConnector appears to be installed." -ForegroundColor Green
    exit 1
}
else {
    Write-Host "ForeScout SecureConnector not detected." -ForegroundColor Red
    exit 0
}
