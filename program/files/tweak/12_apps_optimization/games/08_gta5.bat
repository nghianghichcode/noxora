@echo off
REM Grand Theft Auto V Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Grand Theft Auto V performance tweaks...
reg add "HKCU\Software\Rockstar Games\GTA V" /v "High Priority" /t REG_DWORD /d 1 /f
echo Grand Theft Auto V tweaks applied successfully.
