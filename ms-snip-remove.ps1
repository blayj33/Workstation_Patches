
#!ps
#maxlength=500000
#timeout=900000
# Define minimum safe versions
$minWin10 = [version]"10.2008.3001.0"
$minWin11 = [version]"11.2302.20.0"

# Detect OS version
$osVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
$winVer = (Get-ComputerInfo).WindowsProductName

# Function to check and remove vulnerable app
function Remove-IfVulnerable {
    param(
        [string]$PackageName,
        [version]$MinVersion
    )
    $pkg = Get-AppxPackage -Name $PackageName -AllUsers -ErrorAction SilentlyContinue
    if ($pkg) {
        if ([version]$pkg.Version -lt $MinVersion) {
            Write-Host "Removing vulnerable $PackageName version $($pkg.Version)..." -ForegroundColor Yellow
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers
        } else {
            Write-Host "$PackageName is up to date ($($pkg.Version))." -ForegroundColor Green
        }
    }
}

# Windows 10 – Snip & Sketch
if ($winVer -match "Windows 10") {
    Remove-IfVulnerable -PackageName "Microsoft.ScreenSketch" -MinVersion $minWin10
}

# Windows 11 – Snipping Tool
if ($winVer -match "Windows 11") {
    Remove-IfVulnerable -PackageName "Microsoft.Windows.SnippingTool" -MinVersion $minWin11
}
