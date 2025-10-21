$bypassCheck = $false
$LogDir = "$env:ProgramData\_Windows_Upgrade\logs"
$UseTempFolder = $false
$DownloadDir = "$env:ProgramData\_Windows_Upgrade"
$File = "$DownloadDir\Windows11InstallationAssistant.exe"
$Url = "https://go.microsoft.com/fwlink/?linkid=2171764"

$regKeyPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\MoSetup",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\LabConfig",
    "HKLM:\SYSTEM\Setup"
)

if ($UseTempFolder) {
    $LogDir = "$env:TEMP\_Windows_Upgrade\logs"
}
$LogFilePath = "$LogDir\Win11Compatibility_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

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
    } catch {
        Write-Log "Error creating log directory: $($_.Exception.Message)" "Error"
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
                return $false
            }
            return $true
        } else {
            $Issues.Value += "No TPM detected."
            Write-Log "TPM not found. Check BIOS/UEFI settings."
            return $false
        }
    } catch {
        Write-Log "Error checking TPM: $($_.Exception.Message)" "Error"
        $Issues.Value += "Failed to check TPM."
        return $false
    }
}

function Check-SecureBoot {
    param ([ref]$Issues)
    Write-Log "Checking Secure Boot..."
    try {
        $secureBoot = Confirm-SecureBootUEFI
        Write-Log "Secure Boot Enabled: $secureBoot"
        if (-not $secureBoot) {
            $Issues.Value += "Secure Boot is not enabled."
            Set-CustomRegistryValue "AllowUpgradesWithUnsupportedSecureBoot"
            return $false
        }
        return $true
    } catch {
        Write-Log "Error checking Secure Boot: $($_.Exception.Message)" "Error"
        $Issues.Value += "Secure Boot not supported or disabled. Check BIOS/UEFI."
        Set-CustomRegistryValue "AllowUpgradesWithUnsupportedSecureBoot"
        return $false
    }
}

function Check-UEFI {
    param ([ref]$Issues)
    Write-Log "Checking UEFI firmware..."
    try {
        $firmware = Get-CimInstance -ClassName Win32_ComputerSystem
        $bootMode = $firmware.BootupState
        Write-Log "Boot Mode: $bootMode"
        if ($bootMode -notlike "*UEFI*") {
            $Issues.Value += "System is not using UEFI firmware."
            return $false
        }
        return $true
    } catch {
        Write-Log "Error checking firmware: $($_.Exception.Message)" "Error"
        $Issues.Value += "Failed to check firmware."
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
    $secureBootResult = Check-SecureBoot -Issues ([ref]$Issues)
    $uefiResult = Check-UEFI -Issues ([ref]$Issues)
    $windowsVersionResult = Check-WindowsVersion -Issues ([ref]$Issues)

    $IsCompatible = $cpuResult -and $ramResult -and $storageResult -and $tpmResult -and $secureBootResult -and $uefiResult -and $windowsVersionResult

    Write-Log "Compatibility Check Summary:"
    if ($IsCompatible) {
        Write-Log "System appears compatible with Windows 11." "Success"
    } else {
        Write-Log "System is NOT compatible with Windows 11." "Error"
        Write-Log "Issues found:"
        foreach ($issue in $Issues) {
            Write-Log " - $issue" "Error"
        }
    }
}

function DownloadExe {
    try {
        Write-Log "Downloading using Invoke-WebRequest"
        Invoke-WebRequest -Uri "$Url" -OutFile "$File"
        if (!(Test-Path $File)) {
            Write-Log "Downloaded file does not exist"
            [Environment]::Exit(1)
        }
        Write-Log "Downloaded successfully"
    } catch {
        Write-Log "Error while downloading installer"
        Write-Log $_.Exception.Message
        [Environment]::Exit(1)
    }
}

function upgradeProcess {
    Write-Log "Starting silent upgrade to Windows 11..."
    $Arguments = "/Install /QuietInstall /SkipEULA /copylogs $LogDir"
    try {
        $process = Start-Process -FilePath $File -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-Log "Upgrade process completed successfully."
            Remove-Item $File -Force
        } else {
            Write-Log "Upgrade process failed with exit code: $($process.ExitCode)" "Error"
            exit $process.ExitCode
        }
    } catch {
        Write-Log "Error during upgrade: $($_.Exception.Message)" "Error"
        exit 1
    }
}

function main {
    createLogFolder
    checkCompatibility
    DownloadExe
    upgradeProcess
    Write-Log "Script execution completed. The system will reboot to complete the upgrade."
}

main
