@echo off
REM Disable C-States Idle States
REM Platinum+ Optimizer - CPU Tweaks Module

echo Disabling C-States idle states...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b780d84\5d76a2ae-e8c0-402f-a133-2158492d58ad" /v ValueMax /t REG_DWORD /d 0 /f
powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b780d84 5d76a2ae-e8c0-402f-a133-2158492d58ad 0
powercfg -setdcvalueindex scheme_current 54533251-82be-4824-96c1-47b60b780d84 5d76a2ae-e8c0-402f-a133-2158492d58ad 0
echo C-States idle states disabled successfully.
