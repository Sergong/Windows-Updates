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
- **`ansible.cfg.example`** - Complete example configuration file showing all available Ansible options
- **`inventory.yml`** - Host inventory defining Windows machines to manage
- **`group_vars/windows.yml`** - Group variables for Windows hosts (connection settings)
- **`host_vars/winacemagician.yml`** - Host-specific variables (if exists)

### Playbooks

#### Main Update Playbook
- **`process-windows-updates.yml`** - Comprehensive Windows update management with Wake-on-LAN, Defender handling, and system updates. AWX-compatible with Wake-on-LAN disabled by default (use `--tags never` to skip WOL or `--tags all` to include it)

#### Utility Playbooks
- **`fix-windows-update-remote.yml`** - Troubleshooting playbook for fixing Windows Update issues (clears cache, resets services, re-registers components)
- **`test-connection.yml`** - Simple test playbook to verify Ansible connectivity and gather basic system information from Windows hosts

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
   This is configured in `ansible.cfg` in the `[local]` section but since this is not a valid ansible config file section it is ignored and you will need to export this env var specifically for your shell environment.

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
ansible_shell_type: cmd
ansible_become_method: runas
ansible_remote_tmp: 'C:\Temp\ansible' # Ensure this directory exists!
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
ansible-playbook process-windows-updates.yml
```

#### Wake-on-LAN Control

The Wake-on-LAN task is tagged with `never` to make it AWX-compatible by default:

- **Skip Wake-on-LAN** (default behavior, AWX-compatible):
  ```bash
  ansible-playbook process-windows-updates.yml
  ```

- **Include Wake-on-LAN** (for local execution):
  ```bash
  ansible-playbook process-windows-updates.yml --tags all
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

### Testing Connectivity

To verify Ansible can connect to your Windows machines and gather basic information:
```bash
ansible-playbook test-connection.yml
```

This will:
- Test connection to all Windows hosts in inventory
- Gather system facts (OS, architecture, uptime, etc.)
- Display basic system information

### Manual Wake-on-LAN

To wake your Windows PC manually:
```bash
./wake-my-pc.sh
```

### Targeting Specific Hosts

To run playbooks on specific machines:
```bash
ansible-playbook process-windows-updates.yml --limit your-pc-name
ansible-playbook test-connection.yml --limit your-pc-name
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
8. **Install Defender signatures** (via PowerShell or Ansible module - currently Ansible is uncommented and thus used)
9. **Install critical and security updates** (via PowerShell or Ansible module - currently Ansible is uncommented and thus used)
10. **Re-enable Windows Defender**
11. **Reboot if required**
12. **Perform final verification**

### Update Categories Handled
- **Critical Updates**
- **Security Updates**
- **Update Rollups**
- **Definition Updates** (Windows Defender)
- **General Updates**

## AWX/Ansible Tower Compatibility

This project is designed to work with both standalone Ansible and AWX/Ansible Tower environments:

### Wake-on-LAN Handling
- The Wake-on-LAN task is tagged with `never` by default
- This prevents execution in AWX environments where WOL proxies may not be available
- The task includes a comment explaining it's set to never run by default for AWX compatibility

### Execution in Different Environments

**In AWX/Tower:**
- The playbook runs without Wake-on-LAN by default
- Assumes target machines are already powered on and accessible
- All other functionality remains intact

**Locally/Standalone:**
- Use `--tags always` to include Wake-on-LAN functionality
- Requires `wakeonlan` utility installed on the control machine

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
- `[local]` section for macOS Python 3.13 compatibility fix, but this is ignored by ansible, so export this as an environment var.

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

## Tested Environments

1. macOS
```
ansible [core 2.18.7]
  config file = /Volumes/1TB_Disk/Projects/Windows-Updates/ansible.cfg
  configured module search path = ['/Users/<user>/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /Users/<user>/Library/Python/3.13/lib/python/site-packages/ansible
  ansible collection location = /Users/<user>/.ansible/collections:/usr/share/ansible/collections
  executable location = /Users/<user>/Library/Python/3.13/bin/ansible
  python version = 3.13.5 (main, Jun 11 2025, 15:36:57) [Clang 17.0.0 (clang-1700.0.13.3)] (/opt/homebrew/opt/python@3.13/bin/python3.13)
  jinja version = 3.1.6
  libyaml = True
```
2. AWX
```
______________ 
<  AWX 24.6.1  >
 -------------- 
          \
          \   ^__^
              (oo)\_______
              (__)      A )\
                  ||----w |
                  ||     ||
```

## License

This project is provided as-is for educational and automation purposes. Use at your own risk and ensure you understand the security implications of remote Windows management.

