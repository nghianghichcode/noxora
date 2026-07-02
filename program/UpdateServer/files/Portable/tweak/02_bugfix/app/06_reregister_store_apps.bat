@echo off
REM Re-register Windows Store and Modern Apps
REM Platinum+ Optimizer - Bugfix Module

echo Re-registering Windows Store and modern apps...
powershell -Command "Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\AppXManifest.xml\"}"
powershell -Command "Get-AppxPackage Microsoft.WindowsStore | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\AppXManifest.xml\"}"
echo Windows Store and modern apps re-registered successfully.
