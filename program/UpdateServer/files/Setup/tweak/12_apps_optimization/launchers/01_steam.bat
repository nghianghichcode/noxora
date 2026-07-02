@echo off
REM Steam Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Steam performance tweaks...
reg add "HKCU\Software\Valve\Steam" /v "High Priority" /t REG_DWORD /d 1 /f
echo Steam tweaks applied successfully.
