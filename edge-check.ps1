# Path to msedge.exe
$exePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# 1. Verify installation
if (-not (Test-Path $exePath)) {
    Write-Output "Microsoft Edge Chromium not found at $exePath."
    exit 0
}

# 2. Retrieve installed version
$installedVersion = (Get-Item $exePath).VersionInfo.ProductVersion

# 3. Define patched threshold
$fixedVersion = [version]"140.0.3485.54"

# 4. Compare versions and report
if ([version]$installedVersion -lt $fixedVersion) {
    Write-Output "VULNERABLE: Installed Edge version $installedVersion is older than $fixedVersion."
    exit 1
} else {
    Write-Output "NOT VULNERABLE: Installed Edge version $installedVersion is $fixedVersion or newer."
    exit 0
}
