@echo off
REM Disable Connected User Experiences Telemetry
REM Platinum+ Optimizer - Services Module

echo Disabling Connected User Experiences Telemetry...
sc stop "DiagTrack"
sc config "DiagTrack" start= disabled
echo Telemetry service disabled successfully.
