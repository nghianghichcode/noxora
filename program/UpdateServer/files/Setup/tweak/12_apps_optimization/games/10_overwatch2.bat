@echo off
REM Overwatch 2 Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Overwatch 2 performance tweaks...
reg add "HKCU\Software\Blizzard Entertainment\Overwatch 2" /v "High Priority" /t REG_DWORD /d 1 /f
echo Overwatch 2 tweaks applied successfully.
