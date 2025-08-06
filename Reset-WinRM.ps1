# Stop and disable WinRM
Stop-Service -Name WinRM
Set-Service -Name WinRM -StartupType Disabled

# Delete HTTPS listener
winrm delete winrm/config/Listener?Address=*+Transport=HTTPS

# Reset WinRM config to default
winrm quickconfig -quiet
winrm invoke Restore winrm/Config

# Remove Basic auth and allowunencrypted
winrm set winrm/config/service/auth '@{Basic="false"}'
winrm set winrm/config/service '@{AllowUnencrypted="false"}'

# Clear trusted hosts
winrm set winrm/config/client '@{TrustedHosts=""}'

# Delete firewall rules
netsh advfirewall firewall delete rule name="WinRM HTTP"
netsh advfirewall firewall delete rule name="WinRM HTTPS"

# Remove self-signed certificate (optional)
Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.DnsNameList -contains "win-acemagician" } | Remove-Item

Write-Host "WinRM configuration removed."
