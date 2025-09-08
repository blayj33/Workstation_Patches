# Define the target path
$dir = 'C:\Program Files\ForeScout SecureConnector'

# Check existence, delete if present
if (Test-Path -LiteralPath $dir) {
    Remove-Item -LiteralPath $dir -Recurse -Force
    Write-Output "Successfully deleted:`n$dir"
}
else {
    Write-Warning "Directory not found:`n$dir"
}
