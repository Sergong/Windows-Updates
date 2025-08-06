# Windows 11 WinRM Configuration for Ansible
# Run this script as Administrator on your Windows PC

# Enable PowerShell remoting
Enable-PSRemoting -Force

# Configure WinRM service
winrm quickconfig -force

# Set WinRM configuration for workgroup authentication
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="512"}'

# Configure trusted hosts (allow connections from your Mac)
# Replace 192.168.1.65 with your Mac's IP address
winrm set winrm/config/client '@{TrustedHosts="192.168.1.65,192.168.1.*"}'

# Set up HTTPS listener (recommended for security)
$cert = New-SelfSignedCertificate -DnsName "win-acemagician" -CertStoreLocation Cert:\LocalMachine\My
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"win-acemagician`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"

# Configure Windows Firewall
netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985
netsh advfirewall firewall add rule name="WinRM HTTPS" dir=in action=allow protocol=TCP localport=5986

# Set WinRM service to start automatically
Set-Service -Name WinRM -StartupType Automatic

# Start WinRM service
Start-Service -Name WinRM

Write-Host "WinRM configuration completed!"
Write-Host "Test connection with: winrm identify -r:http://192.168.1.44:5985/wsman"
