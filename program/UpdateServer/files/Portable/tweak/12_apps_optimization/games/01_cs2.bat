@echo off
REM Counter-Strike 2 Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Counter-Strike 2 performance tweaks...
reg add "HKCU\Software\Valve\Counter-Strike 2" /v "High Priority" /t REG_DWORD /d 1 /f
echo Counter-Strike 2 tweaks applied successfully.
