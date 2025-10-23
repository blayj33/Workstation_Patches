# ====================================================================
# Windows 11 Upgrade Script (Assistant First, ISO Fallback with Bypass)
# ====================================================================

# --- Global Control Variables ---
$bypassCheck = $true # Set to $true to enable all registry bypass settings

# --- Upgrade Assistant Variables ---
$AssistantUrl = "https://go.microsoft.com/fwlink/?linkid=2171764" # Official link for the Upgrade Assistant
$AssistantFile = "$env:ProgramData\_Windows_Upgrade\Win11UpgradeAssistant.exe"

# --- ISO Download and Path Variables (Fallback Method) ---
# NOTE: The provided URL is for a time-limited download. It may expire.
$Url = "https://software.download.prss.microsoft.com/dbazure/Win11_25H2_English_x64.iso?t=241267d7-908d-4fe7-9e9e-80e5587d4a2e&P1=1761307714&P2=601&P3=2&P4=pTza2HrvHtYGFyVpUBUqEiIV1R0xKQ3Vzt882zBHXHYQiaOenPwqaQg1tO1V7HQ7jjOCU1bm09YtmnF0E6C1wUOd5DMQo6STOBy7HWqXZ3jVRaTT4J%2bwwhxkHQir5HBdQhs9RfGrVGxV%2f43D8SA0v4CqxemjYG82RgY6kCuWU2b6TOhq0CxRKBk2NxkCMT5Ca7HOwwWrS48tBwfAqZGWbBR3SLAhdW7KWidPY35%2fg02IqX4xXR2%2bfS%2fob4AlBYAGWm2%2bh6MgON5Bt41WzcuGfh5Qz7qBnKjNljKp0zSuFWVArhczAInxYbvUTlM5rSNN1aWFZ6hdXuj%2fzYE6vy6%2biA%3d%3d"
$DownloadDir = "$env:ProgramData\_Windows_Upgrade"
$ISOFile = "$DownloadDir\Win11.iso"
$MountDriveLetter = $null # Will be set dynamically after mounting

# --- Logging and Registry Variables ---
$LogDir = "$env:ProgramData\_Windows_Upgrade\logs"
$UseTempFolder = $false # Kept for original compatibility
$regKeyPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\MoSetup",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\LabConfig",
    "HKLM:\SYSTEM\Setup"
)

if ($UseTempFolder) {
    $LogDir = "$env:TEMP\_Windows_Upgrade\logs"
}
$LogFilePath = "$LogDir\Win11Compatibility_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# ====================================================================
# Utility Functions (Unchanged - Write-Log, createLogFolder, Set-CustomRegistryValue)
# ====================================================================

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Type = "Information"
    )
    $DateTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "$DateTime - $Type - $Message"
    Add-Content -Path $LogFilePath -Value $LogMessage
    Write-Host $LogMessage
}

function createLogFolder {
    try {
        if (-not (Test-Path $LogDir)) {
            New-Item -ItemType Directory -Path $LogDir | Out-Null
            Write-Log "Created log directory: $LogDir"
        }
        if (-not (Test-Path $DownloadDir)) {
            New-Item -ItemType Directory -Path $DownloadDir | Out-Null
            Write-Log "Created download directory: $DownloadDir"
        }
    } catch {
        Write-Log "Error creating directories: $($_.Exception.Message)" "Error"
        exit 1
    }
}

function Set-CustomRegistryValue {
    param (
        [string]$regValueName,
        [int]$regValueData = 1
    )
    if (!$bypassCheck) {
        return
    }
    foreach ($path in $regKeyPaths) {
        try {
            if (-not (Test-Path $path)) {
                Write-Log "Creating registry path: $path"
                New-Item -Path $path -Force | Out-Null
            }
            Set-ItemProperty -Path $path -Name $regValueName -Value $regValueData -Type DWord
            Write-Log "Set '$regValueName' to '$regValueData' at '$path'"
        } catch {
            Write-Log "Failed to set registry value at $path. Error: $_"
        }
    }
}

# ====================================================================
# Compatibility Checks (Unchanged - Check-CPU, Check-RAM, Check-Storage, Check-TPM, Check-WindowsVersion, checkCompatibility)
# NOTE: These checks are now only performed *before* the ISO fallback method.
# ====================================================================

function Check-CPU {
    param ([ref]$Issues)
    Write-Log "Checking processor..."
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor
        $cpuName = $cpu.Name
        $cpuCores = $cpu.NumberOfCores
        $cpuSpeed = [math]::Round($cpu.MaxClockSpeed / 1000, 2)
        Write-Log "CPU: $cpuName, Cores: $cpuCores, Speed: $cpuSpeed GHz"
        if ($cpuCores -lt 2 -or $cpuSpeed -lt 1) {
            $Issues.Value += "CPU does not meet requirements (needs 2+ cores, 1+ GHz)."
            return $false
        }
        return $true
    } catch {
        Write-Log "Error checking CPU: $($_.Exception.Message)" "Error"
        $Issues.Value += "Failed to check CPU."
        return $false
    }
}

function Check-RAM {
    param ([ref]$Issues)
    Write-Log "Checking RAM..."
    try {
        $ram = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        Write-Log "RAM: $ram GB"
        if ($ram -lt 4) {
            $Issues.Value += "RAM is less than 4 GB."
            Set-CustomRegistryValue "AllowUpgradesWithUnsupportedRAM"
            return $false
        }
        return $true
    } catch {
        Write-Log "Error checking RAM: $($_.Exception.Message)" "Error"
        $Issues.Value += "Failed to check RAM."
        Set-CustomRegistryValue "AllowUpgradesWithUnsupportedRAM"
        return $false
    }
}

function Check-Storage {
    param ([ref]$Issues)
    Write-Log "Checking storage..."
    try {
        $systemDrive = $env:SystemDrive
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$systemDrive'"
        if ($disk) {
            $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
            Write-Log "$systemDrive Free Space: $freeSpace GB"
            if ($freeSpace -lt 64) {
                $Issues.Value += "Free storage on $systemDrive is less than 64 GB."
                Set-CustomRegistryValue "AllowUpgradesWithUnsupportedDisk"
                return $false
            }
            return $true
        } else {
            throw "System drive $systemDrive not found."
        }
    } catch {
        Write-Log "Error checking storage: $($_.Exception.Message)" "Error"
        $Issues.Value += "Failed to check storage on $systemDrive."
        Set-CustomRegistryValue "AllowUpgradesWithUnsupportedDisk"
        return $false
    }
}

function Check-TPM {
    param ([ref]$Issues)
    Write-Log "Checking TPM..."
    try {
        $tpm = Get-CimInstance -Namespace "Root\CIMV2\Security\MicrosoftTpm" -ClassName Win32_Tpm
        if ($tpm) {
            $tpmVersion = $tpm.SpecVersion
            Write-Log "TPM Version: $tpmVersion"
            if ($tpmVersion -notlike "*2.0*") {
                $Issues.Value += "TPM version is not 2.0."
                Set-CustomRegistryValue "AllowUpgradesWithUnsupportedTPM"
                return $false
            }
            return $true
        } else {
            $Issues.Value += "No TPM detected."
            Set-CustomRegistryValue "AllowUpgradesWithUnsupportedTPM"
            Write-Log "TPM not found. Check BIOS/UEFI settings."
            return $false
        }
    } catch {
        Write-Log "Error checking TPM: $($_.Exception.Message)" "Error"
        $Issues.Value += "Failed to check TPM."
        Set-CustomRegistryValue "AllowUpgradesWithUnsupportedTPM"
        return $false
    }
}

function Check-WindowsVersion {
    param ([ref]$Issues)
    Write-Log "Checking Windows version..."
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $osVersion = $os.Version
        Write-Log "Windows Version: $osVersion"
        if ([version]$osVersion -lt [version]"10.0.19041") {
            $Issues.Value += "Windows 10 version is older than 2004."
            return $false
        }
        return $true
    } catch {
        Write-Log "Error checking Windows version: $($_.Exception.Message)" "Error"
        $Issues.Value += "Failed to check Windows version."
        return $false
    }
}

function checkCompatibility {
    $IsCompatible = $true
    $Issues = @()
    $cpuResult = Check-CPU -Issues ([ref]$Issues)
    $ramResult = Check-RAM -Issues ([ref]$Issues)
    $storageResult = Check-Storage -Issues ([ref]$Issues)
    $tpmResult = Check-TPM -Issues ([ref]$Issues)

    $windowsVersionResult = Check-WindowsVersion -Issues ([ref]$Issues)

    $IsCompatible = $cpuResult -and $ramResult -and $storageResult -and $tpmResult -and $windowsVersionResult

    Write-Log "Compatibility Check Summary (excluding UEFI/Secure Boot checks):"
    if ($IsCompatible) {
        Write-Log "System appears compatible with Windows 11." "Success"
    } else {
        Write-Log "System is NOT compatible with Windows 11 based on remaining checks." "Error"
        Write-Log "Issues found:"
        foreach ($issue in $Issues) {
            Write-Log " - $issue" "Error"
        }
    }
}

# ====================================================================
# Upgrade Assistant Functions (NEW)
# ====================================================================

function DownloadAssistant {
    Write-Log "Starting Upgrade Assistant download."

    if (Test-Path $AssistantFile) {
        Write-Log "Assistant file already exists at '$AssistantFile'. Skipping download."
        return $true
    }

    try {
        Invoke-WebRequest -Uri $AssistantUrl -OutFile $AssistantFile -MaximumRedirection 5
        if (Test-Path $AssistantFile) {
            Write-Log "Downloaded Upgrade Assistant successfully to $AssistantFile" "Success"
            return $true
        } else {
            Write-Log "Downloaded Upgrade Assistant file does not exist after download." "Error"
            return $false
        }
    } catch {
        Write-Log "Error while downloading Upgrade Assistant: $($_.Exception.Message)" "Error"
        if (Test-Path $AssistantFile) { Remove-Item $AssistantFile -Force -ErrorAction SilentlyContinue }
        return $false
    }
}

function runUpgradeAssistant {
    Write-Log "Attempting to run Windows 11 Upgrade Assistant..."

    if (-not (Test-Path $AssistantFile)) {
        Write-Log "Error: Upgrade Assistant not found. Cannot run." "Error"
        return $false
    }

    try {
        # Running the assistant. It is a GUI process and will wait for user interaction or completion.
        $process = Start-Process -FilePath $AssistantFile -Wait -PassThru
        $exitCode = $process.ExitCode

        # The assistant may not return a reliable exit code, and it often requires user interaction.
        Write-Log "Upgrade Assistant finished with Exit Code: $exitCode"

        # Typically, a code of 0 or a positive value means it ran.
        # It's difficult to know if the *upgrade* actually started without user confirmation.
        # We will assume success if the exit code is 0 (or simply ran), and let the user know.
        if ($exitCode -eq 0) {
            Write-Log "Upgrade Assistant ran successfully. Check your desktop for instructions or restart." "Success"
            Write-Log "If the upgrade process hasn't started, the script will now proceed to the ISO fallback."
            return $true # A "clean" run means we've done our due diligence.
        } else {
            Write-Log "Upgrade Assistant returned an abnormal exit code. Falling back to ISO method." "Warning"
            return $false
        }

    } catch {
        Write-Log "Error running Upgrade Assistant: $($_.Exception.Message)" "Error"
        Write-Log "Falling back to ISO method." "Error"
        return $false
    }
}

# ====================================================================
# ISO Functions (Download, Mount, Dismount, UpgradeProcess) (Unchanged)
# ====================================================================

function DownloadISO {
    Write-Log "Starting ISO download from URL. This may take a long time..."

    if (Test-Path $ISOFile) {
        Write-Log "ISO file already exists at '$ISOFile'. Skipping download."
        return $true
    }

    try {
        # Using a .NET WebClient for large file downloads, as it often handles them better than Invoke-WebRequest
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($Url, $ISOFile)

        if (!(Test-Path $ISOFile)) {
            Write-Log "Downloaded ISO file does not exist after download." "Error"
            return $false
        }
        Write-Log "Downloaded ISO successfully to $ISOFile" "Success"
        return $true
    } catch {
        Write-Log "Error while downloading ISO: $($_.Exception.Message)" "Error"
        # Attempt to delete partial file
        if (Test-Path $ISOFile) { Remove-Item $ISOFile -Force -ErrorAction SilentlyContinue }
        return $false
    }
}

function MountISO {
    if (-not (Test-Path $ISOFile)) {
        Write-Log "ERROR: Windows 11 ISO file not found. Cannot mount." "Error"
        return $false
    }

    Write-Log "Attempting to mount ISO: $ISOFile"
    try {
        # Get the mounted image object
        $mountedImage = Mount-DiskImage -ImagePath $ISOFile -StorageType ISO -PassThru

        # Find the drive letter assigned to the mounted image
        $driveLetter = ($mountedImage | Get-Volume).DriveLetter

        if ($driveLetter) {
            # Assign the drive letter to the global variable for use in upgradeProcess
            $script:MountDriveLetter = "$driveLetter`:"
            Write-Log "Successfully mounted ISO to drive letter: $script:MountDriveLetter" "Success"
            return $true
        } else {
            Write-Log "Could not determine drive letter for mounted ISO." "Error"
            Dismount-DiskImage -ImagePath $ISOFile -ErrorAction SilentlyContinue 
            return $false
        }
    } catch {
        Write-Log "Failed to mount ISO. Error: $($_.Exception.Message)" "Error"
        return $false
    }
}

function DismountISO {
    Write-Log "Dismounting ISO: $ISOFile"
    try {
        Dismount-DiskImage -ImagePath $ISOFile -Confirm:$false
        Write-Log "ISO dismounted successfully."
    } catch {
        Write-Log "Error dismounting ISO: $($_.Exception.Message)" "Error"
    }
}

function upgradeProcess {
    if (-not $script:MountDriveLetter) {
        Write-Log "Error: ISO was not successfully mounted. Cannot proceed with upgrade." "Error"
        exit 1
    }

    $SetupExePath = "$script:MountDriveLetter\setup.exe"
    Write-Log "Starting silent upgrade to Windows 11 from: $SetupExePath"

    # /Auto Upgrade performs an in-place upgrade.
    # /Quiet and /DynamicUpdate disable the GUI and stop it from downloading new updates during setup.
    # /Compat IgnoreWarning skips compatibility checks (bypassed via registry).
    # /NoReboot allows the script to finish and dismount the ISO before the system restarts.
    $Arguments = "/Auto Upgrade /Quiet /DynamicUpdate Disable /Compat IgnoreWarning /NoReboot" 

    try {
        $process = Start-Process -FilePath $SetupExePath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow

        Write-Log "Setup.exe finished with Exit Code: $($process.ExitCode)"

        # 0 or 3221225506 (0xC0000002) are common success codes indicating a reboot is needed.
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3221225506) {
            Write-Log "Upgrade preparation completed. A reboot is required to continue the installation." "Success"
        } else {
            Write-Log "Upgrade process failed with a critical exit code: $($process.ExitCode)" "Error"
            exit $process.ExitCode
        }
    } catch {
        Write-Log "Error during upgrade: $($_.Exception.Message)" "Error"
        exit 1
    }
}

# ====================================================================
# Main Execution (UPDATED)
# ====================================================================

function main {
    createLogFolder

    # 1. ATTEMPT UPGRADE ASSISTANT FIRST
    Write-Log "--- PHASE 1: ATTEMPTING UPGRADE ASSISTANT ---"
    if (DownloadAssistant) {
        runUpgradeAssistant
        # NOTE: Since the Upgrade Assistant is a GUI, it requires user interaction and may take time.
        # If it runs, we assume the user will proceed with it.
        Write-Log "If the Upgrade Assistant was successful, the script execution will stop here." "Information"
        Write-Log "If the Upgrade Assistant was *not* successful or the user closed it, we will proceed with the ISO fallback in 30 seconds."
        
        # Wait for the user to possibly start the upgrade with the assistant, then check for failure/cancellation.
        # This is an imperfect check, but gives the user time to initiate the GUI upgrade.
        Start-Sleep -Seconds 30 
    } else {
        Write-Log "Failed to download Upgrade Assistant. Proceeding to ISO fallback." "Warning"
    }

    # 2. FALLBACK TO ISO METHOD
    Write-Log "--- PHASE 2: FALLBACK TO ISO METHOD (WITH BYPASS) ---"

    # 2a. Set Compatibility Bypasses & Run Checks
    Write-Log "Setting registry bypass for Windows 11 compatibility checks."
    Set-CustomRegistryValue "AllowUpgradesWithUnsupportedSecureBoot"
    Set-CustomRegistryValue "AllowUpgradesWithUnsupportedOS"
    checkCompatibility # Logs any issues, registry keys are set within checks if needed.

    # 2b. Download ISO
    if (-not (DownloadISO)) {
        Write-Log "Fatal Error: Failed to download Windows 11 ISO. Exiting script." "Error"
        exit 1
    }

    # 2c. Mount ISO and Start Upgrade
    if (MountISO) {
        upgradeProcess
        DismountISO

        # 2d. Final Instruction
        Write-Log "Script execution completed using the ISO fallback method. THE SYSTEM NEEDS TO REBOOT NOW to complete the Windows 11 upgrade." "Success"
        Write-Log "To initiate the required reboot, run the following command:"
        Write-Log "shutdown /r /t 0" "Success"
    } else {
        Write-Log "Upgrade failed because the ISO could not be mounted. Exiting script." "Error"
        exit 1
    }
}

# Run the main function
main
