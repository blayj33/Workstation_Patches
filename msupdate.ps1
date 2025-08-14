#!ps
#timeout=3600000
$PSWindowsUpdateModule = Get-Module PSWindowsUpdate -ListAvailable
If ($PSWindowsUpdateModule -eq $Null) {
Write-Output "Installing PSWindowsUpdate Module"
Install-Module -Name PSWindowsUpdate -Force
}
Write-Output "Install Windows Updates"
Import-Module PSWindowsUpdate
Install-WindowsUpdate -AcceptAll
