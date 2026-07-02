@echo off
REM Disable Automatic Updates
REM Platinum+ Optimizer - System Tweaks Module

echo Disabling automatic updates...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f
echo Automatic updates disabled successfully.
