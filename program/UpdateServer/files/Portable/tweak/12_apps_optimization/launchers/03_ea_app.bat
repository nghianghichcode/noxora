@echo off
REM EA App Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying EA App performance tweaks...
reg add "HKCU\Software\Electronic Arts\EA Desktop" /v "High Priority" /t REG_DWORD /d 1 /f
echo EA App tweaks applied successfully.
