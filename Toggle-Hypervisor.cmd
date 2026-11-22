@echo off
rem Double-click launcher for Toggle-Hypervisor.ps1 (asks for admin via UAC).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Toggle-Hypervisor.ps1" %*
