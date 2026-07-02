@echo off
REM Uninstall Microsoft OneDrive
REM Platinum+ Optimizer - Debloat Module

echo Uninstalling Microsoft OneDrive...
taskkill /f /im OneDrive.exe
%SystemRoot%\System32\OneDriveSetup.exe /uninstall
echo OneDrive uninstalled successfully.
