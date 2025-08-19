#!ps
#maxlength=500000
#timeout=900000
# Suppress non-terminating errors (e.g. access denied)
$ErrorActionPreference = 'SilentlyContinue'

# Enumerate all filesystem drives and recurse for the EXE
Get-PSDrive -PSProvider FileSystem |
  ForEach-Object {
    Get-ChildItem -Path $_.Root `
                  -Filter 'CellebriteReader.exe' `
                  -Recurse `
                  -Force
  } |
  Select-Object -ExpandProperty FullName
