@echo off
REM Spotify Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Spotify performance tweaks...
reg add "HKCU\Software\Spotify" /v "High Priority" /t REG_DWORD /d 1 /f
echo Spotify tweaks applied successfully.
