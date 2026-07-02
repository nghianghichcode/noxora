@echo off
REM Disable Print Spooler Service
REM Platinum+ Optimizer - Services Module

echo Disabling Print Spooler Service...
sc stop "Spooler"
sc config "Spooler" start= disabled
echo Print Spooler Service disabled successfully.
