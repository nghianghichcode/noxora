@echo off
REM Uninstall Xbox Game Bar
REM Platinum+ Optimizer - Debloat Module

echo Uninstalling Xbox Game Bar...
powershell -Command "Get-AppxPackage Microsoft.XboxGamingOverlay | Remove-AppxPackage"
echo Xbox Game Bar uninstalled successfully.
