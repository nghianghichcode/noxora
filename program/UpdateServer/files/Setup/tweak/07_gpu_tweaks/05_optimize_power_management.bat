@echo off
REM Optimize Power Management
REM Platinum+ Optimizer - GPU Tweaks Module

echo Optimizing GPU power management...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v DisableCudaContextPreemption /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v DisablePreemption /t REG_DWORD /d 1 /f
echo GPU power management optimized successfully.
