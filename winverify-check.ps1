#!ps
#maxlength=500000
#timeout=900000
# Detection script for EnableCertPaddingCheck registry values

$regPaths = @(
    "HKLM:\Software\Microsoft\Cryptography\Wintrust\Config",
    "HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"
)

$compliant = $true

foreach ($path in $regPaths) {
    if (Test-Path $path) {
        $value = Get-ItemProperty -Path $path -Name "EnableCertPaddingCheck" -ErrorAction SilentlyContinue
        if ($null -eq $value.EnableCertPaddingCheck -or $value.EnableCertPaddingCheck -ne 1) {
            $compliant = $false
        }
    } else {
        $compliant = $false
    }
}

if ($compliant) {
    Write-Output "Compliant"
    exit 0
} else {
    Write-Output "Non-Compliant"
    exit 1
}
