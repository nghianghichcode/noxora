@echo off
REM Enable Hardware GPU Scheduling
REM Platinum+ Optimizer - GPU Tweaks Module

echo Enabling hardware GPU scheduling...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f
echo Hardware GPU scheduling enabled successfully.
