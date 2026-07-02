@echo off
REM Rainbow Six Siege Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Rainbow Six Siege performance tweaks...
reg add "HKCU\Software\Ubisoft\Rainbow Six Siege" /v "High Priority" /t REG_DWORD /d 1 /f
echo Rainbow Six Siege tweaks applied successfully.
