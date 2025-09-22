# Define the minimum safe version
$minVersion = [version]"1.6.00.26474"

# Get all user profile directories under C:\Users
$profiles = Get-ChildItem "$env:SystemDrive\Users" -Directory

foreach ($profile in $profiles) {
    $teamsPath = Join-Path $profile.FullName "AppData\Local\Microsoft\Teams\current\Teams.exe"
    if (Test-Path $teamsPath) {
        try {
            $fileVersion = (Get-Item $teamsPath).VersionInfo.FileVersion
            $ver = [version]$fileVersion
            if ($ver -lt $minVersion) {
                Write-Host "Deleting outdated Teams.exe ($fileVersion) from $teamsPath" -ForegroundColor Yellow
                Remove-Item $teamsPath -Force
            } else {
                Write-Host "Teams.exe at $teamsPath is up-to-date ($fileVersion)" -ForegroundColor Green
            }
        } catch {
            Write-Host "Error checking $teamsPath : $_" -ForegroundColor Red
        }
    }
}
