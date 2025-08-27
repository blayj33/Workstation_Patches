#!ps
#maxlength=500000
#timeout=900000
# Detect Microsoft Teams installs prior to or equal to 1.6.00.26474
$ErrorActionPreference = "Stop"
$targetVersion = [Version]"1.6.00.26474"
$found = $false

Get-ChildItem 'C:\Users' -Directory |
Where-Object { $_.Name -notin 'Default','Public','All Users' } |
ForEach-Object {
    $teamsExe = "$($_.FullName)\AppData\Local\Microsoft\Teams\current\Teams.exe"
    if (Test-Path $teamsExe) {
        try {
            $version = [Version](Get-Item $teamsExe).VersionInfo.ProductVersion
            if ($version -le $targetVersion) {
                Write-Output "User '$($_.Name)' has Teams version $version (<= $targetVersion)."
                $found = $true
            }
        } catch {
            Write-Output "Error reading Teams version for '$($_.Name)': $_"
        }
    }
}

if (-not $found) {
    Write-Output "No Teams installations found at version $targetVersion or lower."
}

exit 0

