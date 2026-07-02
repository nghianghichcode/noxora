@echo off
REM Optimize GPU Priority
REM Platinum+ Optimizer - GPU Tweaks Module

echo Optimizing GPU priority...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\igfxEM.exe" /v PerfOptions /t REG_DWORD /d 16 /f
echo GPU priority optimized successfully.
