#!ps
#maxlength=500000
#timeout=900000

# Install or update the Windows Package Manager (winget)

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    # Download the latest App Installer bundle and install winget
    $url  = 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
    $file = Join-Path $env:TEMP 'AppInstaller.msixbundle'

    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $file
    Add-AppxPackage    -Path $file
    Remove-Item        -Path $file -Force

    Write-Output 'winget has been installed.'
}
else {
    # If already present, update to the latest winget
    winget upgrade `
      --id Microsoft.DesktopAppInstaller `
      --silent `
      --accept-source-agreements `
      --accept-package-agreements

    Write-Output 'winget has been updated.'
}
