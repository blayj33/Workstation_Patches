
$guid = '{E3344F20-4344-46B2-9BEA-6A7602250FB7}'
Start-Process msiexec.exe `
  -ArgumentList "/x $guid /qn /norestart" `
  -Wait -NoNewWindow
