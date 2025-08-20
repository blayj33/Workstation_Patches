# Define the registry paths and values to be set
$registryPaths = @(
    "HKLM:\Software\Microsoft\Cryptography\Wintrust\Config",
    "HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"
)

$regName = "EnableCertPaddingCheck"
$desiredValue = "1"

foreach ($regPath in $registryPaths) {
    try {
        # Create the registry key if it doesn't exist
        if (-not (Test-Path -Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
            Write-Output "Created registry key path: $regPath"
        }

        # Set the registry value as REG_SZ
        Set-ItemProperty -Path $regPath -Name $regName -Value $desiredValue -Type String -Force
        Write-Output "Successfully set registry value to $desiredValue for $regPath"
    } catch {
        Write-Output ("Failed to set registry value for {0}: {1}" -f $regPath, $_.Exception.Message)
        exit 1
    }
}

exit 0
