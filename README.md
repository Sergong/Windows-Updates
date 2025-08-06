# Windows Updates Management with Ansible

This repository provides an automated solution for managing Windows updates using Ansible. It includes comprehensive scripts for both initial setup and ongoing maintenance of Windows systems through remote management protocols (WinRM and SSH).

## Overview

The project automates Windows Update management with the following key features:
- **Wake-on-LAN** functionality to wake sleeping Windows machines
- **Multiple update strategies** for handling Defender signatures and system updates
- **Temporary Defender disabling** to prevent interference during updates
- **Automatic reboot handling** when required
- **Service management** and Windows Update troubleshooting
- **Flexible connection methods** (WinRM and SSH)

## Repository Structure

### Core Ansible Files
- **`ansible.cfg`** - Ansible configuration with macOS Python 3.13 compatibility fixes
- **`inventory.yml`** - Host inventory defining Windows machines to manage
- **`group_vars/windows.yml`** - Group variables for Windows hosts (connection settings)
- **`host_vars/winacemagician.yml`** - Host-specific variables (if exists)

### Playbooks

#### Main Update Playbooks
- **`check-windows-updates.yml`** - Comprehensive update management with detailed logging and both PowerShell and Ansible module approaches
- **`windows-update-defender-fixed.yml`** - Streamlined update process with specific focus on Defender signature handling

#### Utility Playbooks
- **`fix-windows-update-remote.yml`** - Troubleshooting playbook for fixing Windows Update issues (clears cache, resets services, re-registers components)

### Windows Setup Scripts
- **`setup-winrm.ps1`** - PowerShell script to configure WinRM on Windows for Ansible management
- **`Setup-OpenSSH.ps1`** - PowerShell script to set up OpenSSH server on Windows (alternative to WinRM)
- **`Reset-WinRM.ps1`** - PowerShell script to remove WinRM configuration and clean up

### Helper Files
- **`wake-my-pc.sh`** - Standalone bash script for wake-on-LAN functionality
- **`filter_plugins/update_filters.py`** - Custom Ansible filters for processing update data

## Prerequisites

### On the Control Machine (macOS/Linux)
1. **Ansible** with Windows modules:
   ```bash
   pip install ansible pywinrm
   ```

2. **Wake-on-LAN utility**:
   ```bash
   # macOS with Homebrew
   brew install wakeonlan
   
   # Linux (Ubuntu/Debian)
   sudo apt install wakeonlan
   
   # Linux (RHEL/Fedora)
   sudo dnf install wakeonlan
   ```

3. **macOS Sequoia (15.x) Compatibility**:
   If using Python 3.13 on macOS Sequoia, export this environment variable:
   ```bash
   export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
   ```
   This is already configured in `ansible.cfg` but may be needed for your shell environment.

### On Windows Target Machines
1. **PowerShell execution policy** set to allow script execution
2. **Wake-on-LAN enabled** in BIOS/UEFI and network adapter settings
3. **Administrator privileges** for initial setup

## Initial Setup

### 1. Configure Windows Machine

Run **ONE** of these setup scripts as Administrator on your Windows machine:

#### Option A: WinRM Setup (HTTP/HTTPS)
```powershell
.\setup-winrm.ps1
```
This configures WinRM with both HTTP (port 5985) and HTTPS (port 5986) listeners.

#### Option B: SSH Setup (Recommended)
```powershell
.\Setup-OpenSSH.ps1
```
This installs and configures OpenSSH server with PowerShell as the default shell.

### 2. Update Inventory Configuration

Edit `inventory.yml` to match your Windows machine:
```yaml
windows:
  hosts:
    your-pc-name:
      ansible_host: 192.168.1.xxx    # Your Windows PC IP
      mac_address: "XX:XX:XX:XX:XX:XX"  # MAC address for Wake-on-LAN
      ip_address: "192.168.1.xxx"      # Same as ansible_host
      broadcast: "192.168.1.255"       # Your network's broadcast address
```

### 3. Configure Connection Method

Edit `group_vars/windows.yml` based on your chosen setup:

#### For SSH (Recommended):
```yaml
ansible_connection: ssh
ansible_shell_type: powershell
ansible_become_method: runas
```

#### For WinRM:
```yaml
ansible_connection: winrm
ansible_winrm_transport: basic
ansible_winrm_server_cert_validation: ignore
ansible_winrm_port: 5985  # or 5986 for HTTPS
ansible_winrm_scheme: http  # or https
ansible_become_method: runas
```

## Usage

### Basic Update Management

Run the main update playbook:
```bash
ansible-playbook check-windows-updates.yml
```

Or use the streamlined version:
```bash
ansible-playbook windows-update-defender-fixed.yml
```

### Troubleshooting Windows Updates

If Windows Update is not working properly:
```bash
ansible-playbook fix-windows-update-remote.yml
```

This playbook will:
- Stop Windows Update services
- Clear update cache directories
- Reset registry keys
- Re-register Windows Update components
- Reset proxy settings
- Restart services
- Test connectivity to Microsoft update servers

### Manual Wake-on-LAN

To wake your Windows PC manually:
```bash
./wake-my-pc.sh
```

### Targeting Specific Hosts

To run playbooks on specific machines:
```bash
ansible-playbook check-windows-updates.yml --limit your-pc-name
```

## Playbook Features

### Update Process Flow
1. **Wake the target machine** using Wake-on-LAN
2. **Wait for system responsiveness**
3. **Gather system information**
4. **Temporarily disable Windows Defender** real-time protection
5. **Restart Windows Update service**
6. **Search for available updates**
7. **Separate Defender updates from system updates**
8. **Install Defender signatures** (via PowerShell or Ansible module)
9. **Install critical and security updates**
10. **Re-enable Windows Defender**
11. **Reboot if required**
12. **Perform final verification**

### Update Categories Handled
- **Critical Updates**
- **Security Updates**
- **Update Rollups**
- **Definition Updates** (Windows Defender)
- **General Updates**

## Configuration Options

### Variables
Customize behavior in playbooks or group_vars:
- `reboot_timeout: 900` - Maximum time to wait for reboot (seconds)
- `update_timeout: 7200` - Maximum time for update operations (seconds)

### Ansible Configuration
The `ansible.cfg` file includes optimizations:
- YAML output formatting
- Disabled deprecation warnings
- SSH pipelining for performance
- macOS Python 3.13 compatibility fixes

## Security Considerations

### WinRM Security
- Uses Basic authentication over HTTP (consider HTTPS for production)
- Firewall rules are automatically configured
- TrustedHosts configuration allows your control machine

### SSH Security
- More secure than WinRM over HTTP
- Uses standard SSH authentication
- PowerShell is set as the default shell

### Defender Management
- Real-time protection is temporarily disabled during updates
- Automatically re-enabled after completion
- Helps prevent update interference

## Troubleshooting

### Common Issues

1. **Connection timeouts**: Verify firewall settings and network connectivity
2. **Authentication failures**: Check user credentials and connection method configuration
3. **Wake-on-LAN not working**: Verify BIOS settings and network adapter configuration
4. **Updates failing**: Run the `fix-windows-update-remote.yml` playbook
5. **Python 3.13 crashes on macOS**: Ensure `OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` is set

### Reset Windows Configuration

To remove WinRM configuration:
```powershell
.\Reset-WinRM.ps1
```

## Contributing

When contributing:
1. Test on your specific Windows version
2. Ensure compatibility with both SSH and WinRM
3. Update documentation for new features
4. Consider security implications of changes

## License

This project is provided as-is for educational and automation purposes. Use at your own risk and ensure you understand the security implications of remote Windows management.

