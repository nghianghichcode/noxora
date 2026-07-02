@echo off
REM Disable Startup Delay
REM Platinum+ Optimizer - System Tweaks Module

echo Disabling startup delay...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f
echo Startup delay disabled successfully.
