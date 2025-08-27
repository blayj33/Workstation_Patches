#!ps
#maxlength=500000
#timeout=900000
# Uninstall Teams for all users if version < 1.6.00.26474
$ErrorActionPreference = "Stop"
$targetVersion = [Version]"1.6.00.26474"

Get-ChildItem 'C:\Users' -Directory |
Where-Object { $_.Name -notin 'Default','Public','All Users' } |
ForEach-Object {
    $teamsPath = "$($_.FullName)\AppData\Local\Microsoft\Teams"
    $updateExe = Join-Path $teamsPath 'Update.exe'
    $teamsExe  = Join-Path $teamsPath 'current\Teams.exe'

    if ((Test-Path $updateExe) -and (Test-Path $teamsExe)) {
        try {
            $version = [Version](Get-Item $teamsExe).VersionInfo.ProductVersion
            if ($version -lt $targetVersion) {
                Write-Output "Uninstalling Teams for '$($_.Name)' (v$version)..."
                $code = (Start-Process $updateExe -ArgumentList "-uninstall -s" -Wait -PassThru).ExitCode
                if ($code -eq 0) { Write-Output "Uninstalled successfully." }
                else { Write-Output "Uninstall failed. ExitCode: $code" }
                if (Test-Path $teamsPath) {
                    Remove-Item $teamsPath -Recurse -Force
                    Write-Output "Removed Teams directory."
                }
            } else {
                Write-Output "Skipping '$($_.Name)'; v$version is current."
            }
        } catch {
            Write-Output "Error processing '$($_.Name)': $_"
        }
    }
}

exit 0
