# Define the product GUIDs you want to remove
$guids = @(
    '{E3344F20-4344-46B2-9BEA-6A7602250FB7}',
    '{5C53F83F-8530-49BD-B1B9-C2E0A3F98507}',
    '{8F477957-4A80-4514-9943-25A7614782B0}',
    '{CC016DCE-E309-403C-81DB-442F680E18AC}',
    '{57AB3D40-C876-4CAF-88CD-3BBFC669479C}'
)

# 32-bit uninstall registry hive on 64-bit Windows
$uninstallRoot = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

foreach ($guid in $guids) {
    $regKey = Join-Path $uninstallRoot $guid

    if (Test-Path $regKey) {
        Write-Host "Found $guid – uninstalling…" -ForegroundColor Cyan
        Start-Process msiexec.exe `
            -ArgumentList "/x $guid /qn /norestart" `
            -Wait -NoNewWindow
    }
    else {
        Write-Host "GUID $guid not present in 32-bit Uninstall hive." -ForegroundColor Yellow
    }
}
