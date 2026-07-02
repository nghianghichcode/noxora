@echo off
REM Disable Core Parking
REM Platinum+ Optimizer - CPU Tweaks Module

echo Disabling core parking...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b780d84\0cc5b647-1e2d-4235-a5d2-934c6a6b0d27" /v ValueMax /t REG_DWORD /d 100 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b780d84\0cc5b647-1e2d-4235-a5d2-934c6a6b0d27" /v ValueMin /t REG_DWORD /d 100 /f
powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b780d84 0cc5b647-1e2d-4235-a5d2-934c6a6b0d27 100
powercfg -setdcvalueindex scheme_current 54533251-82be-4824-96c1-47b60b780d84 0cc5b647-1e2d-4235-a5d2-934c6a6b0d27 100
echo Core parking disabled successfully.
