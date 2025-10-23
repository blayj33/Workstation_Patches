<#
This resource is provided as a convenience for Level users. We cannot 
guarantee it will work in all environments. Please test before deploying 
to your production environment. We welcome contributions to our community 
library

Level Library
https://level.io/library/script-upgrade-to-windows-11
#>

# Step 1: Setup
Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [INFO] - Script started..."

# Define necessary paths and variables
$installerPath = "C:\temp\Windows11UpdateAssistant.exe"
$tempDir = "C:\temp"

# Step 2: Check if temporary directory exists, create if not
if (-Not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [INFO] - Created directory '$tempDir'."
} else {
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [INFO] - Directory '$tempDir' already exists."
}

# Step 3: Download the Windows 11 Installation Assistant
$url = "https://go.microsoft.com/fwlink/?linkid=2171764"
try {
    Invoke-WebRequest -Uri $url -OutFile $installerPath -ErrorAction Stop
    $FileSize = [math]::round((Get-Item -Path $installerPath).Length/1MB,2)
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [INFO] - Windows 11 Installation Assistant downloaded to '$installerPath' - $FileSize MB."
} catch {
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [ERROR] - Failed to download Windows 11 Installation Assistant. $_"
    exit 1
}

# Step 4: Start the Windows 11 upgrade process
Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [INFO] - Starting Windows 11 upgrade process."
$process = Start-Process -FilePath $installerPath -ArgumentList "/quietinstall /skipeula /auto upgrade /NoRestartUI /noreboot /copylogs $tempDir" -PassThru -Wait

# Step 5: Check if the process was successfully initiated and check the exit code
if ($process.ExitCode -ne 0) {
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [ERROR] - The Windows 11 upgrade process failed with exit code $($process.ExitCode)."
    
    # Step 6: Extract errors from setup logs if available
    if (Test-Path $tempDir) {
        $setupActLog = Join-Path -Path $tempDir -ChildPath "setupact.log"
        $setupErrLog = Join-Path -Path $tempDir -ChildPath "setuperr.log"

        # Extract errors and warnings from setupact.log
        if (Test-Path $setupActLog) {
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [DEBUG] - Extracting warnings and errors from '$setupActLog'."
            Select-String -Path $setupActLog -Pattern "Error", "Warning" | ForEach-Object {
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [DEBUG] - $($_.Line)"
            }
        }
        
        # Extract errors and warnings from setuperr.log
        if (Test-Path $setupErrLog) {
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [DEBUG] - Extracting warnings and errors from '$setupErrLog'."
            Select-String -Path $setupErrLog -Pattern "Error", "Warning" | ForEach-Object {
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [DEBUG] - $($_.Line)"
            }
        }
    }

    exit 1
} else {
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [INFO] - The Windows 11 upgrade process completed successfully with exit code 0."
}

# Step 7: Clean up the installer
if (Test-Path $installerPath) {
    Remove-Item -Path $installerPath -Force
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [INFO] - Cleaned up installer from '$installerPath'."
}

# Step 8: Exit with a success code
exit 0
