@echo off
REM Disable Advertising ID
REM Platinum+ Optimizer - System Tweaks Module

echo Disabling advertising ID...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f
echo Advertising ID disabled successfully.
