@echo off
REM League of Legends Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying League of Legends performance tweaks...
reg add "HKCU\Software\Riot Games\RADS" /v "High Priority" /t REG_DWORD /d 1 /f
echo League of Legends tweaks applied successfully.
