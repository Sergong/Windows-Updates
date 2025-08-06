# Windows Updates

This repo contains ansible code to keep Windows Hosts up-to-date using Windows Update. It also contains a powershell script to set up the Windows hosts to be managed using WinRM (which ansible uses to communicate with Windows Hosts)

> When running on macOS Sequoia (15.x) there is a problem when using Python 3.13 and certain ansible modules (such as `ansible.builtin.wait_for_connection`) in that python crashes when forking a process. This can be mitigated by setting the following Environment variable:
`export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES`

