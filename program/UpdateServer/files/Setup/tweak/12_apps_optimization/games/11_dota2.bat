@echo off
REM Dota 2 Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Dota 2 performance tweaks...
reg add "HKCU\Software\Valve\Dota 2" /v "High Priority" /t REG_DWORD /d 1 /f
echo Dota 2 tweaks applied successfully.
