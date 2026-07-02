@echo off
REM GOG Galaxy Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying GOG Galaxy performance tweaks...
reg add "HKCU\Software\GOG.com\Galaxy" /v "High Priority" /t REG_DWORD /d 1 /f
echo GOG Galaxy tweaks applied successfully.
