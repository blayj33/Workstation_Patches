# Ensure the script runs elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Error 'Please rerun this script as Administrator.'
    exit 1
}

# GUIDs of the PowerShell 7.x MSIs you want to remove (no braces here)
$ids = @(
    'E3344F20-4344-46B2-9BEA-6A7602250FB7',  # PowerShell 
    '5C53F83F-8530-49BD-B1B9-C2E0A3F98507',  # PowerShell 7.4.5
    '8F477957-4A80-4514-9943-25A7614782B0',  # PowerShell 7.4.3
    'CC016DCE-E309-403C-81DB-442F680E18AC',  # PowerShell 7.4.6
    '57AB3D40-C876-4CAF-88CD-3BBFC669479C',  # PowerShell 7.4.7
    'C2219E29-B390-4FD6-958F-469F68C20B9F'   # PowerShell 7.5.1
)

# Registry hives for 64-bit and 32-bit MSI registrations
$hives = @{
    '64-bit' = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    '32-bit' = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
}

foreach ($id in $ids) {
    $guid      = "{${id}}"
    $foundHive = $null

    # Detect which hive contains the product
    foreach ($arch in $hives.Keys) {
        if (Test-Path "$($hives[$arch])\$guid") {
            $foundHive = $arch
            break
        }
    }

    if (-not $foundHive) {
        Write-Host "GUID $guid not present in any Uninstall hive, skipping." -ForegroundColor Yellow
        continue
    }

    # Choose the matching msiexec host
    $msiExec = if ($foundHive -eq '32-bit') {
        "$env:WinDir\SysWOW64\msiexec.exe"
    } else {
        "$env:WinDir\System32\msiexec.exe"
    }

    Write-Host "Uninstalling $guid (registered in $foundHive hive)..." -ForegroundColor Cyan
    $proc = Start-Process -FilePath $msiExec `
                          -ArgumentList "/x $guid /qn /norestart" `
                          -Wait -PassThru

    switch ($proc.ExitCode) {
        0    { Write-Host "→ $guid removed successfully." -ForegroundColor Green }
        1605 { Write-Host "→ $guid already uninstalled." -ForegroundColor DarkGray }
        default { Write-Warning "→ Failed to remove $guid (ExitCode=$($proc.ExitCode))." }
    }
}
