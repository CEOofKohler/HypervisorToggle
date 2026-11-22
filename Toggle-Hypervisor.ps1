<#
    Toggle-Hypervisor.ps1  (Windows PowerShell 5.1)

    Switches Windows between two modes:
      Gaming mode - hypervisor OFF: VALORANT / Vanguard works, Docker Desktop and WSL2 do not.
      Docker mode - hypervisor ON : Docker Desktop and WSL2 work, VALORANT gives VAN9005.

    The change only takes effect after a full RESTART (not Shut down - Fast Startup
    would keep the old setting).

    Usage:
      Double-click Toggle-Hypervisor.cmd, or run:
        .\Toggle-Hypervisor.ps1                 (menu)
        .\Toggle-Hypervisor.ps1 -Mode Gaming
        .\Toggle-Hypervisor.ps1 -Mode Docker
        .\Toggle-Hypervisor.ps1 -Mode Toggle
#>
param(
    [ValidateSet('Gaming', 'Docker', 'Toggle')]
    [string]$Mode
)

$ErrorActionPreference = 'Stop'

# --- Re-launch as administrator if needed (bcdedit requires it) ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Mode) { $argList += @('-Mode', $Mode) }
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs
    } catch {
        Write-Host '[X] Administrator permission is required. Nothing was changed.'
        Read-Host 'Press Enter to close'
    }
    exit
}

function Get-HypervisorLaunchType {
    $out = & bcdedit.exe /enum '{current}' 2>&1
    if ($LASTEXITCODE -ne 0) { throw "bcdedit failed: $($out -join ' ')" }
    foreach ($line in $out) {
        if ("$line" -match '^\s*hypervisorlaunchtype\s+(\S+)') { return $Matches[1] }
    }
    return 'Off'   # Not set at all means the hypervisor is not launched.
}

function Get-ModeName([string]$launchType) {
    if ($launchType -ieq 'Off') { return 'Gaming' } else { return 'Docker' }
}

try {
    $current     = Get-HypervisorLaunchType
    $currentMode = Get-ModeName $current
    $running     = [bool](Get-CimInstance Win32_ComputerSystem).HypervisorPresent

    Write-Host ''
    Write-Host '=== Hypervisor toggle (VALORANT vs Docker) ==='
    Write-Host ("Boot setting         : {0}  -> {1} mode" -f $current, $currentMode)
    Write-Host ("Hypervisor running now: {0}" -f $(if ($running) { 'Yes (Docker mode active)' } else { 'No (Gaming mode active)' }))
    if (($currentMode -eq 'Gaming') -eq $running) {
        Write-Host '[!] The boot setting and the running state differ - a restart is still pending.'
    }
    Write-Host ''

    if (-not $Mode) {
        Write-Host '  1) Gaming mode - hypervisor OFF (VALORANT works, Docker/WSL2 do not)'
        Write-Host '  2) Docker mode - hypervisor ON  (Docker/WSL2 work, VALORANT gives VAN9005)'
        Write-Host '  Q) Quit without changing anything'
        $choice = (Read-Host 'Choose').Trim().ToUpper()
        switch ($choice) {
            '1'     { $Mode = 'Gaming' }
            '2'     { $Mode = 'Docker' }
            default { Write-Host 'Nothing changed.'; exit }
        }
    }

    if ($Mode -eq 'Toggle') {
        $Mode = if ($currentMode -eq 'Gaming') { 'Docker' } else { 'Gaming' }
    }
    $target = if ($Mode -eq 'Gaming') { 'off' } else { 'auto' }

    if ($currentMode -eq $Mode) {
        Write-Host "[OK] Already set to $Mode mode."
    } else {
        $out = & bcdedit.exe /set '{current}' hypervisorlaunchtype $target 2>&1
        if ($LASTEXITCODE -ne 0) { throw "bcdedit failed: $($out -join ' ')" }
        Write-Host "[OK] Switched to $Mode mode (hypervisorlaunchtype = $target)."
    }

    # Restart needed if what's running doesn't match the chosen mode.
    $needRestart = ($Mode -eq 'Gaming') -eq $running
    if (-not $needRestart) {
        Write-Host '[OK] No restart needed - this mode is already active.'
        Read-Host 'Press Enter to close'
        exit
    }

    Write-Host ''
    Write-Host 'A full restart is needed for this to take effect.'
    Write-Host 'Save your work first. Use Restart, not Shut down (Fast Startup keeps the old setting).'
    $answer = (Read-Host 'Restart now? (Y/N)').Trim().ToUpper()
    if ($answer -eq 'Y') {
        Restart-Computer
    } else {
        Write-Host 'OK - restart later from Start > Power > Restart.'
        Read-Host 'Press Enter to close'
    }
} catch {
    Write-Host "[X] Error: $($_.Exception.Message)"
    Write-Host 'Nothing else was changed.'
    Read-Host 'Press Enter to close'
}
