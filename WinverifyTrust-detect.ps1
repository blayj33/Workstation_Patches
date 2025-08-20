# Define the registry paths and values to check
$registryPaths = @(
    "HKLM:\Software\Microsoft\Cryptography\Wintrust\Config",
    "HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"
)

$regName = "EnableCertPaddingCheck"
$expectedValue = 1

# Variable to track compliance
$compliant = $true

foreach ($regPath in $registryPaths) {
    if (Test-Path -Path $regPath) {
        $currentValue = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $regName

        if ($null -ne $currentValue -and $currentValue -eq $expectedValue) {
            Write-Output "Compliant: Registry value is set correctly for $regPath"
        } else {
            Write-Output "Non-compliant: Registry value is not set correctly for $regPath"
            $compliant = $false
        }
    } else {
        Write-Output "Non-compliant: Registry path not found: $regPath"
        $compliant = $false
    }
}

# Output the compliance status
if ($compliant) {
    Write-Output "Compliant: All specified registry values are set correctly."
    exit 0
} else {
    Write-Output "Non-compliant: One or more specified registry values are not set correctly."
    exit 1
}
