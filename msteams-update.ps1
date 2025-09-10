# Define variables
$msiUrl  = 'https://statics.teams.cdn.office.net/evergreen-assets/DesktopClient/MSTeamsSetup.exe'
$msiPath = "$env:TEMP\Teams_x64.msi"

# Download the latest MSI
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing

# Install/upgrade machine-wide (per-user installs are automatically updated)
Start-Process -FilePath msiexec.exe `
    -ArgumentList "/i `"$msiPath`" ALLUSER=1 ALLUSERCONTEXT=1 /qn /norestart" `
    -Wait

# Clean up
Remove-Item -Path $msiPath -Force

Write-Output "Teams MSI deployed. Verify with:"
Write-Output "  (Get-Item '\$env:ProgramFiles\Teams Installer\Teams.exe').VersionInfo.FileVersion"
