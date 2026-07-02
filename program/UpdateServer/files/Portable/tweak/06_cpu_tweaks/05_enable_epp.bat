@echo off
REM Enable Energy Performance Preference
REM Platinum+ Optimizer - CPU Tweaks Module

echo Enabling energy performance preference...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b780d84\36679629-e496-4d54-95ba-cf59af89a274" /v ValueMax /t REG_DWORD /d 0 /f
powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b780d84 36679629-e496-4d54-95ba-cf59af89a274 0
powercfg -setdcvalueindex scheme_current 54533251-82be-4824-96c1-47b60b780d84 36679629-e496-4d54-95ba-cf59af89a274 0
echo Energy performance preference enabled successfully.
