@echo off
REM Valorant Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Valorant performance tweaks...
reg add "HKCU\Software\Riot Games\VALORANT" /v "High Priority" /t REG_DWORD /d 1 /f
echo Valorant tweaks applied successfully.
