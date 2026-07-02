@echo off
REM OBS Studio Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying OBS Studio performance tweaks...
reg add "HKCU\Software\OBSStudio" /v "High Priority" /t REG_DWORD /d 1 /f
echo OBS Studio tweaks applied successfully.
