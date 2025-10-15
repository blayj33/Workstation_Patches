#!ps
#maxlength=500000
#timeout=900000
# Create Wintrust\Config if it doesn't exist
if (!(Test-Path 'HKLM:\Software\Microsoft\Cryptography\Wintrust\Config')) {
    New-Item -Path 'HKLM:\Software\Microsoft\Cryptography\Wintrust' -Name 'Config' -Force | Out-Null
}
Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Cryptography\Wintrust\Config' -Name 'EnableCertPaddingCheck' -Value 1 -Type DWord

# Create Wow6432Node\Wintrust\Config if it doesn't exist
if (!(Test-Path 'HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config')) {
    New-Item -Path 'HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust' -Name 'Config' -Force | Out-Null
}
Set-ItemProperty -Path 'HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config' -Name 'EnableCertPaddingCheck' -Value 1 -Type DWord
