#!ps
#maxlength=500000
#timeout=900000
﻿
# Detection Script: Check for Updates of Installed Built-in Applications
# Update Winget sources to ensure latest package information
winget source update
# List of target applications with their Winget IDs
$apps = @{
   "Microsoft.Paint3D"                      = "Microsoft.Paint3D"
   "Microsoft.Calculator"                   = "Microsoft.WindowsCalculator"
   "Microsoft.SnippingTool"                 = "Microsoft.ScreenSketch"          # Snip & Sketch
   "Microsoft.3DViewer"                     = "Microsoft.3DViewer"
   "Microsoft.MicrosoftStickyNotes"         = "Microsoft.MicrosoftStickyNotes"
   "Microsoft.ZuneMusic"                    = "Microsoft.ZuneMusic"             # Groove Music
   "Microsoft.ZuneVideo"                    = "Microsoft.ZuneVideo"             # Movies & TV
   "Microsoft.MicrosoftSolitaireCollection" = "Microsoft.MicrosoftSolitaireCollection"
   "Microsoft.Whiteboard"                   = "Microsoft.Whiteboard"
   "Microsoft.Windows.RawImage"             = "Microsoft.Windows.RawImage"       # Raw Image Extension
   "Microsoft.WindowsTerminal"              = "Microsoft.WindowsTerminal"
   "Microsoft.WindowsNotepad"               = "Microsoft.WindowsNotepad"
   "Microsoft.PowerToys"                    = "Microsoft.PowerToys"             # Optional: PowerToys
   "Microsoft.YourPhone"                    = "Microsoft.YourPhone"             # Optional: Your Phone
   "Microsoft.ToDo"                         = "Microsoft.ToDo"                  # Optional: Microsoft To Do
   # Add more applications as needed
}
$updatesAvailable = @()
foreach ($app in $apps.GetEnumerator()) {
   try {
       # Check if the application is installed
       $installedApp = winget list --id $app.Value --source winget --exact 2>$null
       if ($null -eq $installedApp) {
           # Application is not installed; skip to the next
           continue
       }
       # Extract the installed version
       $installedVersion = ($installedApp | Select-Object -Skip 1 | ForEach-Object {
           $_ -split '\s{2,}' | Select-Object -Index 1
       }) -as [Version]
       if (-not $installedVersion) {
           Write-Output "Unable to determine installed version for $($app.Key). Skipping."
           continue
       }
       # Get the latest version from Winget
       $wingetInfo = winget show --id $app.Value --source winget
       $latestVersionLine = $wingetInfo | Where-Object { $_ -like "Version*" }
       $latestVersion = ($latestVersionLine -replace "Version\s*:", "").Trim() -as [Version]
       if (-not $latestVersion) {
           Write-Output "Unable to determine latest version for $($app.Key). Skipping."
           continue
       }
       # Compare versions
       if ($installedVersion -lt $latestVersion) {
           $updatesAvailable += "$($app.Key) has an update available. Installed: $installedVersion, Latest: $latestVersion"
       }
   }
   catch {
       Write-Output "Error checking $($app.Key): $_"
       # Optionally, you can choose to log or handle the error differently
   }
}
# Output results for Intune
if ($updatesAvailable.Count -gt 0) {
   # Non-zero exit code indicates that remediation is needed
   Write-Output "Updates Available:`n$($updatesAvailable -join "`n")"
   exit 1
}
else {
   Write-Output "All targeted applications are up-to-date."
   exit 0
}