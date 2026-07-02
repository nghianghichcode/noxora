@echo off
REM Battle.net Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Battle.net performance tweaks...
reg add "HKCU\Software\Blizzard Entertainment\Battle.net" /v "High Priority" /t REG_DWORD /d 1 /f
echo Battle.net tweaks applied successfully.
