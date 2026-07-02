@echo off
REM Uninstall Microsoft Edge Chromium
REM Platinum+ Optimizer - Debloat Module

echo Uninstalling Microsoft Edge Chromium...
powershell -Command "Get-AppxPackage Microsoft.MicrosoftEdge.Stable | Remove-AppxPackage"
echo Microsoft Edge Chromium uninstalled successfully.
