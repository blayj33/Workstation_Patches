#!ps
#maxlength=500000
#timeout=900000

# Run as Administrator
$session = New-Object -ComObject Microsoft.Update.Session
$searcher = $session.CreateUpdateSearcher()
$results  = $searcher.Search("IsInstalled=0 and IsHidden=0 and Type='Software'")

if ($results.Updates.Count -eq 0) {
    Write-Output "No updates available."
    return
}

Write-Output "Found $($results.Updates.Count) updates:"
$results.Updates | ForEach-Object { Write-Output "- $($_.Title)" }

$collection = New-Object -ComObject Microsoft.Update.UpdateColl
$results.Updates | ForEach-Object { $collection.Add($_) | Out-Null }

$downloader = $session.CreateUpdateDownloader()
$downloader.Updates = $collection
Write-Output "Downloading updates..."
$downloader.Download()

$installer = $session.CreateUpdateInstaller()
$installer.Updates = $collection
Write-Output "Installing updates..."
$installer.Install() | Out-Null

Write-Output "All done."
