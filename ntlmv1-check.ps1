<#  
.SYNOPSIS  
  Intune Proactive Remediation detection:  
  - LMCompatibilityLevel must equal 3  
  - NoLMHash must exist and equal 1  

.DESCRIPTION  
  If either check fails, exit code 1 is returned to trigger the remediation script.  
  If both pass, exit code 0 signals “all good.”  
#>

$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
$vulnFound = $false

# 1) Check LMCompatibilityLevel
try {
    $lm = Get-ItemPropertyValue -Path $regPath -Name 'LMCompatibilityLevel' -ErrorAction Stop
    if ($lm -ne 3) { $vulnFound = $true }
}
catch {
    # missing key also means vulnerable
    $vulnFound = $true
}

# 2) Check NoLMHash
try {
    $noLm = Get-ItemPropertyValue -Path $regPath -Name 'NoLMHash' -ErrorAction Stop
    if ($noLm -ne 1) { $vulnFound = $true }
}
catch {
    # missing key => vulnerable
    $vulnFound = $true
}

if ($vulnFound) {
    Write-Output 'VULNERABLE: LMCompatibilityLevel<>3 or NoLMHash missing/<>1'
    exit 1
}
else {
    Write-Output 'COMPLIANT: LMCompatibilityLevel=3 and NoLMHash=1'
    exit 0
}
