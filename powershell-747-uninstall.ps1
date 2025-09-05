# GUIDs of PowerShell instances to remove from the 32-bit Uninstall hive
$guids = @(
    '{E3344F20-4344-46B2-9BEA-6A7602250FB7}',  # PS 7-x64
    '{5C53F83F-8530-49BD-B1B9-C2E0A3F98507}',  # PS 7.4.5
    '{8F477957-4A80-4514-9943-25A7614782B0}',  # PS 7.4.3
    '{CC016DCE-E309-403C-81DB-442F680E18AC}',  # PS 7.4.6
    '{57AB3D40-C876-4CAF-88CD-3BBFC669479C}',  # PS 7.4.7
    '{C2219E29-B390-4FD6-958F-469F68C20B9F}'   # PS 7.5.1
)

$uninstallRoot = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

foreach ($guid in $guids) {
    $keyPath = "$uninstallRoot\$guid"
    if (Test-Path $keyPath) {
        Write-Host "Uninstalling $guid…" -ForegroundColor Cyan
        & msiexec.exe /x $guid /qn /norestart
    }
    else {
        Write-Host "GUID $guid not found, skipping." -ForegroundColor Yellow
    }
}
