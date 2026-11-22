# Hypervisor Toggle (VALORANT / Docker)

Switch Windows between two boot modes with one double-click:

| Mode   | Hypervisor | Works                          | Doesn't work                    |
|--------|------------|--------------------------------|---------------------------------|
| Gaming | Off        | VALORANT / Riot Vanguard       | Docker Desktop, WSL2            |
| Docker | On         | Docker Desktop, WSL2           | VALORANT (Vanguard error VAN9005) |

## Why

On PCs without TPM 2.0 / Secure Boot, turning on the Windows hypervisor (which Docker Desktop
and WSL2 do) also turns on Virtualization-Based Security. Vanguard then refuses to run with
**VAN9005 - "This build of Vanguard is out of compliance with current system settings."**
Turning the hypervisor off while playing avoids it.

## Usage

Double-click `Toggle-Hypervisor.cmd` (it asks for admin), then pick a mode. Or from PowerShell:

```powershell
.\Toggle-Hypervisor.ps1                # menu
.\Toggle-Hypervisor.ps1 -Mode Gaming   # hypervisor off
.\Toggle-Hypervisor.ps1 -Mode Docker   # hypervisor on
.\Toggle-Hypervisor.ps1 -Mode Toggle   # switch to the other mode
```

It changes `hypervisorlaunchtype` in the boot configuration (`bcdedit`), so a **restart** is
needed. Use Restart, not Shut down: with Fast Startup on, a shutdown keeps the old setting.

Requires Windows PowerShell 5.1 and administrator rights.
