@echo off
REM Chrome Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Chrome performance tweaks...
reg add "HKCU\Software\Google\Chrome" /v "High Priority" /t REG_DWORD /d 1 /f
echo Chrome tweaks applied successfully.
