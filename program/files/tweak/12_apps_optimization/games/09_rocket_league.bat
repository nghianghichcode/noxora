@echo off
REM Rocket League Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Rocket League performance tweaks...
reg add "HKCU\Software\Psyonix\Rocket League" /v "High Priority" /t REG_DWORD /d 1 /f
echo Rocket League tweaks applied successfully.
