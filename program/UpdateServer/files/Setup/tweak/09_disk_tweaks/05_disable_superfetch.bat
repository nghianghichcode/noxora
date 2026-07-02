@echo off
REM Disable Superfetch SysMain
REM Platinum+ Optimizer - Disk Tweaks Module

echo Disabling Superfetch SysMain...
sc stop "SysMain"
sc config "SysMain" start= disabled
echo Superfetch SysMain disabled successfully.
