@echo off
REM Disable Geolocation Tracking Service
REM Platinum+ Optimizer - Services Module

echo Disabling Geolocation Tracking Service...
sc stop "lfsvc"
sc config "lfsvc" start= disabled
echo Geolocation Tracking Service disabled successfully.
