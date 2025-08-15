#!ps
#maxlength=500000
#timeout=900000
# Determine installed version via WMI
$curVer = [version]((Get-WmiObject Win32_InstalledStoreProgram `
    -Filter "Name='Microsoft.ScreenSketch'").Version)

# Pick target build by OS
$osCaption = (Get-CimInstance Win32_OperatingSystem).Caption
$target  = if ($osCaption -like '*Windows 10*') {
    [version]'10.2008.3001.0'
} else {
    [version]'11.2302.20.0'
}

# Compare and update if behind
if ($curVer -lt $target) {
    Write-Output "Updating Snip & Sketch/Snipping Tool: $curVer → $target"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Microsoft.ScreenSketch --exact --silent
    } else {
        Write-Warning 'winget not found; please install the package manually.'
    }
} else {
    Write-Output "Compliant: $curVer ≥ $target"
}
