# Ensure script runs as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as Administrator."
    exit 1
}

# Define download URL and destination path
$msiUrl  = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/311f0c4f-89f0-415f-a56a-74060ca99bd0/MicrosoftEdgeEnterpriseX64.msi"
$dest    = Join-Path $env:TEMP "MicrosoftEdgeEnterpriseX64.msi"

# Download the MSI package
Write-Output "Downloading Microsoft Edge MSI to $dest..."
Invoke-WebRequest -Uri $msiUrl -OutFile $dest -UseBasicParsing

# Install silently
Write-Output "Installing Microsoft Edge silently..."
Start-Process msiexec.exe -ArgumentList "/i `"$dest`" /qn /norestart" -Wait -NoNewWindow

# Cleanup
Remove-Item $dest -ErrorAction SilentlyContinue

Write-Output "Microsoft Edge installation complete."
