@echo off
REM Disable Windows Error Reporting
REM Platinum+ Optimizer - Services Module

echo Disabling Windows Error Reporting...
sc stop "WerSvc"
sc config "WerSvc" start= disabled
echo Windows Error Reporting disabled successfully.
