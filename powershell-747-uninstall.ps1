# Ensure we’re running elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run as Administrator."
    exit 1
}

# List of MSI product GUIDs to remove
$msiGuids = @(
    '{E3344F20-4344-46B2-9BEA-6A7602250FB7}',  # PowerShell 7-x64
    '{5c53f83f-8530-49bd-b1b9-c2e0a3f98507}',  # Powershell 7.4.5
    '{8f477957-4a80-4514-9943-25a7614782b0}',  # Powershell 7.4.3
    '{cc016dce-e309-403c-81db-442f680e18ac}',  # Powershell 7.4.6
    '{57ab3d40-c876-4caf-88cd-3bbfc669479c}'   # PowerShell 7.4.7.0-x64
)

foreach ($guid in $msiGuids) {
    # Check both 64-bit and Wow6432Node uninstall hives
    $key64 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid"
    $key32 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$guid"

    if (Test-Path $key64 -PathType Container -or Test-Path $key32 -PathType Container) {
        Write-Host "Uninstalling MSI $guid…" -ForegroundColor Cyan
        Start-Process msiexec.exe `
            -ArgumentList "/x $guid /qn /norestart" `
            -Wait -NoNewWindow

        if ($LASTEXITCODE -eq 0) {
            Write-Host "→ Successfully removed $guid" -ForegroundColor Green
        }
        else {
            Write-Warning "→ Uninstall of $guid exited with code $LASTEXITCODE"
        }
    }
    else {
        Write-Host "MSI $guid not present, skipping." -ForegroundColor DarkGray
    }
}
