@echo off
REM Ubisoft Connect Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Ubisoft Connect performance tweaks...
reg add "HKCU\Software\Ubisoft\Ubisoft Connect" /v "High Priority" /t REG_DWORD /d 1 /f
echo Ubisoft Connect tweaks applied successfully.
