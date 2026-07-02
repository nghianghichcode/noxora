@echo off
REM Uninstall Cortana
REM Platinum+ Optimizer - Debloat Module

echo Uninstalling Cortana...
powershell -Command "Get-AppxPackage Microsoft.549981C3F5F10 | Remove-AppxPackage"
echo Cortana uninstalled successfully.
