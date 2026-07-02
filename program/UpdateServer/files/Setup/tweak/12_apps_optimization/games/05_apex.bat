@echo off
REM Apex Legends Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Apex Legends performance tweaks...
reg add "HKCU\Software\Respawn\Apex" /v "High Priority" /t REG_DWORD /d 1 /f
echo Apex Legends tweaks applied successfully.
