<#
.SYNOPSIS
    Silently uninstalls specified MSI products by GUID, then cleans up any leftover registry entries.

.DESCRIPTION
    This script locates each GUID in both 64-bit and 32-bit MSI Uninstall hives, invokes the product’s
    UninstallString (or msiexec /x {GUID}) with silent flags, waits for completion, checks exit codes,
    and finally removes any orphaned registry key.

.NOTES
    - Must be run as Administrator.
    - Supports exit codes 0, 3010 (reboot required), 1605 (not installed), and reports failures otherwise.
#>

# Ensure elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Throw "Script must be run as Administrator."
}

# List of product GUIDs (without braces)
$GuidsToUninstall = @(
    'E3344F20-4344-46B2-9BEA-6A7602250FB7',
    '5C53F83F-8530-49BD-B1B9-C2E0A3F98507',
    '8F477957-4A80-4514-9943-25A7614782B0',
    'CC016DCE-E309-403C-81DB-442F680E18AC',
    '57AB3D40-C876-4CAF-88CD-3BBFC669479C',
    'C2219E29-B390-4FD6-958F-469F68C20B9F'
    'a609cfee-e0e7-40cd-984e-5d3031037f8a'
)

# Registry roots to search
$RegistryRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)

foreach ($guid in $GuidsToUninstall) {
    $braced = "{${guid}}"
    $foundKey = $null

    # Locate the registry key
    foreach ($root in $RegistryRoots) {
        $path = Join-Path $root $braced
        if (Test-Path $path) {
            $foundKey = $path
            break
        }
    }

    if (-not $foundKey) {
        Write-Host "→ $braced not found in registry. Skipping." -ForegroundColor DarkGray
        continue
    }

    # Read the UninstallString; fall back to msiexec /x if missing
    $uninstallString = (Get-ItemProperty -Path $foundKey -Name UninstallString `
                       -ErrorAction SilentlyContinue).UninstallString
    if ([string]::IsNullOrWhiteSpace($uninstallString)) {
        $exe  = Join-Path $env:WinDir 'System32\msiexec.exe'
        $args = "/x $braced /qn /norestart"
    }
    else {
        # Split the stored string into executable + args
        if ($uninstallString -match '^(?<exe>".+?"|[^\s]+)\s*(?<args>.*)$') {
            $exe  = $Matches.exe.Trim('"')
            $args = $Matches.args
        }
        else {
            # fallback if the regex fails
            $exe  = Join-Path $env:WinDir 'System32\msiexec.exe'
            $args = "/x $braced"
        }

        # Ensure silent flags
        if ($args -notmatch '/qn')        { $args += ' /qn' }
        if ($args -notmatch '/norestart') { $args += ' /norestart' }
    }

    Write-Host "→ Uninstalling $braced via `"$exe`" $args" -ForegroundColor Cyan

    # Execute uninstall
    $proc = Start-Process -FilePath $exe `
                          -ArgumentList $args `
                          -Wait -PassThru `
                          -ErrorAction SilentlyContinue

    switch ($proc.ExitCode) {
        0    { $status = "Removed successfully.";        $color = 'Green'  }
        3010 { $status = "Removed (reboot required).";    $color = 'Yellow' }
        1605 { $status = "Not installed or already removed."; $color = 'Gray' }
        default {
            $status = "Failed (ExitCode=$($proc.ExitCode))."
            $color  = 'Red'
        }
    }
    Write-Host "  ↳ $status" -ForegroundColor $color

    # Clean up orphaned registry key
    if (Test-Path $foundKey) {
        try {
            Remove-Item -Path $foundKey -Recurse -Force
            Write-Host "  ↳ Orphaned registry key removed." -ForegroundColor DarkGray
        }
        catch {
            Write-Warning "  ↳ Could not remove registry key: $_"
        }
    }
}
