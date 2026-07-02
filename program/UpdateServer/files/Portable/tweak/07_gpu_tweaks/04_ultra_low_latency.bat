@echo off
REM Enable Ultra Low Latency Mode
REM Platinum+ Optimizer - GPU Tweaks Module

echo Enabling ultra low latency mode...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v LatencyMode /t REG_DWORD /d 1 /f
echo Ultra low latency mode enabled successfully.
