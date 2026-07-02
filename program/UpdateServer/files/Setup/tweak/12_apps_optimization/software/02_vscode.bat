@echo off
REM Visual Studio Code Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Visual Studio Code performance tweaks...
reg add "HKCU\Software\Microsoft\VSCode" /v "High Priority" /t REG_DWORD /d 1 /f
echo Visual Studio Code tweaks applied successfully.
