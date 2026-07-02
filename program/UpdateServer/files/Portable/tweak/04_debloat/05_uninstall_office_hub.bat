@echo off
REM Uninstall Get Office Hub and Solitaire
REM Platinum+ Optimizer - Debloat Module

echo Uninstalling Get Office Hub and Solitaire...
powershell -Command "Get-AppxPackage Microsoft.Office.OneNote | Remove-AppxPackage"
powershell -Command "Get-AppxPackage Microsoft.MicrosoftSolitaireCollection | Remove-AppxPackage"
echo Get Office Hub and Solitaire uninstalled successfully.
