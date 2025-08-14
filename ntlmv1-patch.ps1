<#
.SYNOPSIS
  Remediates NTLMv1/LanMan authentication by enforcing NTLMv2-only.

.DESCRIPTION
  Sets LMCompatibilityLevel to 3 and ensures NoLMHash is enabled (1).

.NOTES
  Run as Administrator. Exits 0 on success, 1 on error.
#>

# Require elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Error "This script must be run as Administrator."
  exit 1
}

$regPath = 'HKLM:\System\CurrentControlSet\Control\Lsa'

try {
  # Ensure the key exists
  if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
  }

  # Enforce NTLMv2 only (disable LM & NTLMv1)
  Set-ItemProperty -Path $regPath `
                   -Name 'LMCompatibilityLevel' `
                   -Value 3 `
                   -Type DWord

  # Enable NoLMHash (prevents storing LM hashes)
  if (-not (Get-ItemProperty -Path $regPath -Name 'NoLMHash' -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $regPath `
                     -Name 'NoLMHash' `
                     -PropertyType DWord `
                     -Value 1 | Out-Null
  }
  else {
    Set-ItemProperty -Path $regPath `
                     -Name 'NoLMHash' `
                     -Value 1 `
                     -Type DWord
  }

  Write-Host "Remediation applied: LMCompatibilityLevel=3, NoLMHash=1" -ForegroundColor Green
  exit 0
}
catch {
  Write-Error "Failed to apply remediation: $_"
  exit 1
}
