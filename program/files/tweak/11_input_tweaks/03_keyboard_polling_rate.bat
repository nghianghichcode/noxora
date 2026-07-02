@echo off
REM Keyboard Polling Rate Tweaks
REM Platinum+ Optimizer - Input Tweaks Module

echo Optimizing keyboard polling rate...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4D36E96B-E325-11CE-BFC1-08002BE10318}" /v PollingIntervalPlay /t REG_DWORD /d 1 /f
echo Keyboard polling rate optimized successfully.
