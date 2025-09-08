# Check if SupportAssist is installed and upgrade it
if (winget list --id Dell.SupportAssist) {
  winget upgrade --id Dell.SupportAssist --silent --accept-source-agreements --accept-package-agreements
}
else {
  winget install --id Dell.SupportAssist --silent --accept-source-agreements --accept-package-agreements
}
