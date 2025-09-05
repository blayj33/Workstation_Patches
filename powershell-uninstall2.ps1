# List of product codes (without braces)
$GuidsToUninstall = @(
  'E3344F20-4344-46B2-9BEA-6A7602250FB7',
  '5C53F83F-8530-49BD-B1B9-C2E0A3F98507',
  '8F477957-4A80-4514-9943-25A7614782B0',
  'CC016DCE-E309-403C-81DB-442F680E18AC',
  '57AB3D40-C876-4CAF-88CD-3BBFC669479C',
  'C2219E29-B390-4FD6-958F-469F68C20B9F',
  'a609cfee-e0e7-40cd-984e-5d3031037f8a'
)

# Roots to clean under (registry hives and Package Cache folder)
$Roots = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
  'C:\ProgramData\Package Cache'
)

foreach ($guid in $GuidsToUninstall) {
  $braced = "{${guid}}"
  foreach ($root in $Roots) {
    $path = Join-Path $root $braced
    if (Test-Path $path) {
      Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
      Write-Host "Removed: $path"
    }
  }
}
