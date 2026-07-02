@echo off
REM Optimize Priority Separation
REM Platinum+ Optimizer - CPU Tweaks Module

echo Optimizing priority separation...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f
echo Priority separation optimized successfully.
