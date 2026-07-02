@echo off
REM Adobe Photoshop Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Adobe Photoshop performance tweaks...
reg add "HKCU\Software\Adobe\Photoshop" /v "High Priority" /t REG_DWORD /d 1 /f
echo Adobe Photoshop tweaks applied successfully.
