
# Array of MSI product GUIDs (no braces needed here)
$guids = @(
    '{E3344F20-4344-46B2-9BEA-6A7602250FB7}',  # PowerShell 7-x64
    '{5c53f83f-8530-49bd-b1b9-c2e0a3f98507}',  # Powershell 7.4.5
    '{8f477957-4a80-4514-9943-25a7614782b0}',  # Powershell 7.4.3
    '{cc016dce-e309-403c-81db-442f680e18ac}',  # Powershell 7.4.6
    '{57ab3d40-c876-4caf-88cd-3bbfc669479c}'   # PowerShell 7.4.7.0-x64
)

foreach ($id in $guids) {
  Write-Host "Processing $id…" -ForegroundColor Cyan

  # Launch msiexec and capture its exit code
  & msiexec.exe /x "{$id}" /qn /norestart
  $rc = $LASTEXITCODE

  switch ($rc) {
    0     { Write-Host "→ Uninstalled $id successfully." -ForegroundColor Green }
    1605  { Write-Host "→ $id not found, skipping." -ForegroundColor DarkGray }
    default {
      Write-Warning "→ Failed to remove $id (exit code: $rc)."
    }
  }
}

