#!ps
#maxlength=500000
#timeout=900000
# Define the expected executable and directory paths
$pathsToCheck = @(
    Join-Path $env:ProgramFiles     'ForeScout SecureConnector\SecureConnector.exe',
    Join-Path $env:ProgramFiles     'ForeScout SecureConnector',
    Join-Path $env:ProgramFiles(x86) 'ForeScout SecureConnector\SecureConnector.exe',
    Join-Path $env:ProgramFiles(x86) 'ForeScout SecureConnector'
)

# Iterate through each path and test for existence
$found = $false
foreach ($path in $pathsToCheck) {
    if (Test-Path $path) {
        Write-Output "✅ Found: $path"
        $found = $true
    }
}

if (-not $found) {
    Write-Output "❌ ForeScout SecureConnector not installed or directory not present under Program Files."
    exit 1
}
else {
    exit 0
}
