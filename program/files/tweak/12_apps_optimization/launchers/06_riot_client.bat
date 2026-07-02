@echo off
REM Riot Client Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Riot Client performance tweaks...
reg add "HKCU\Software\Riot Games\Riot Client" /v "High Priority" /t REG_DWORD /d 1 /f
echo Riot Client tweaks applied successfully.
