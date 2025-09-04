# List of PowerShell MSI product GUIDs to uninstall
$guids = @(
    '{E3344F20-4344-46B2-9BEA-6A7602250FB7}',  # PowerShell 7-x64
    '{5c53f83f-8530-49bd-b1b9-c2e0a3f98507}',  # PowerShell 7.4.5
    '{8f477957-4a80-4514-9943-25a7614782b0}',  # PowerShell 7.4.3
    '{cc016dce-e309-403c-81db-442f680e18ac}',  # PowerShell 7.4.6
    '{57ab3d40-c876-4caf-88cd-3bbfc669479c}'   # PowerShell 7.4.7
)

foreach ($guid in $guids) {
    Start-Process msiexec.exe `
      -ArgumentList "/x $guid /qn /norestart" `
      -Wait -NoNewWindow
}
