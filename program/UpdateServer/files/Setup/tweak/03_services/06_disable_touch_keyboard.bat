@echo off
REM Disable Touch Keyboard Panel
REM Platinum+ Optimizer - Services Module

echo Disabling Touch Keyboard Panel...
sc stop "TabletInputService"
sc config "TabletInputService" start= disabled
echo Touch Keyboard Panel disabled successfully.
