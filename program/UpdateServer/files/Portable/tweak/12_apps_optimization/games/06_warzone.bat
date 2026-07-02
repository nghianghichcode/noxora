@echo off
REM Call of Duty: Warzone Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Call of Duty: Warzone performance tweaks...
reg add "HKCU\Software\Activision\Warzone" /v "High Priority" /t REG_DWORD /d 1 /f
echo Call of Duty: Warzone tweaks applied successfully.
