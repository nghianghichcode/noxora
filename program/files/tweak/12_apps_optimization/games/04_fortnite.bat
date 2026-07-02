@echo off
REM Fortnite Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Fortnite performance tweaks...
reg add "HKCU\Software\Epic Games\Fortnite" /v "High Priority" /t REG_DWORD /d 1 /f
echo Fortnite tweaks applied successfully.
