@echo off
REM Xbox App Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Xbox App performance tweaks...
reg add "HKCU\Software\Microsoft\Xbox" /v "High Priority" /t REG_DWORD /d 1 /f
echo Xbox App tweaks applied successfully.
