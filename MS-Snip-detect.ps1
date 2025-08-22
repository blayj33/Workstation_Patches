
#!ps
#maxlength=500000
#timeout=900000
# Minimum safe versions
$minWin10 = [version]"10.2008.3001.0"
$minWin11 = [version]"11.2302.20.0"

# Get OS name
$winVer = (Get-ComputerInfo).WindowsProductName

function Check-Vulnerability {
    param(
        [string]$PackageName,
        [version]$MinVersion
    )
    $pkg = Get-AppxPackage -Name $PackageName -AllUsers -ErrorAction SilentlyContinue
    if ($pkg) {
        if ([version]$pkg.Version -lt $MinVersion) {
            Write-Host "VULNERABLE: $PackageName version $($pkg.Version) is below $MinVersion" -ForegroundColor Red
        } else {
            Write-Host "SAFE: $PackageName version $($pkg.Version) meets or exceeds $MinVersion" -ForegroundColor Green
        }
    } else {
        Write-Host "$PackageName is not installed." -ForegroundColor Yellow
    }
}

# Windows 10 – Snip & Sketch
if ($winVer -match "Windows 10") {
    Check-Vulnerability -PackageName "Microsoft.ScreenSketch" -MinVersion $minWin10
}

# Windows 11 – Snipping Tool
if ($winVer -match "Windows 11") {
    Check-Vulnerability -PackageName "Microsoft.Windows.SnippingTool" -MinVersion $minWin11
}
