#!ps
#timeout=3600000
<#
.SYNOPSIS
  Searches for, downloads, and installs all pending Windows updates with progress logging.

.NOTES
  - Requires running as Administrator.
  - Recommended to run under AllSigned execution policy.
#>

# Simple logger with timestamps
function Log {
    param([string]$Message)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$time] $Message"
}

try {
    Log "Initializing Windows Update session..."
    $session   = New-Object -ComObject Microsoft.Update.Session
    $searcher  = $session.CreateUpdateSearcher()

    Log "Searching for updates..."
    $results = $searcher.Search("IsInstalled=0 and IsHidden=0")

    if ($results.Updates.Count -eq 0) {
        Log "No applicable updates found. Exiting."
        return
    }
    Log "Found $($results.Updates.Count) update(s)."

    # Collect updates
    $collection = New-Object -ComObject Microsoft.Update.UpdateColl
    foreach ($u in $results.Updates) { $collection.Add($u) | Out-Null }

    Log "Starting download..."
    $downloader            = $session.CreateUpdateDownloader()
    $downloader.Updates    = $collection
    $downloader.Download() | Out-Null
    Log "Download complete."

    Log "Starting installation..."
    $installer             = $session.CreateUpdateInstaller()
    $installer.Updates     = $collection
    $result = $installer.Install()
    
    switch ($result.ResultCode) {
        2 { Log "Installation succeeded. Reboot may be required." }
        default { Log "Finished with result code $($result.ResultCode)." }
    }
}
catch {
    Log "ERROR: $($_.Exception.Message)"
    exit 1
}
