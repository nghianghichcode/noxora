@echo off
REM Disable Cortana Telemetry
REM Platinum+ Optimizer - System Tweaks Module

echo Disabling Cortana telemetry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v CortanaEnabled /t REG_DWORD /d 0 /f
echo Cortana telemetry disabled successfully.
