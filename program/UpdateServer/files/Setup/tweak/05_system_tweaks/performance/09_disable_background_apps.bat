@echo off
REM Disable Background Apps
REM Platinum+ Optimizer - System Tweaks Module

echo Disabling background apps...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f
echo Background apps disabled successfully.
