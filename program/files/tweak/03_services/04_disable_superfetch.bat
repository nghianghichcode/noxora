@echo off
REM Disable SysMain Superfetch
REM Platinum+ Optimizer - Services Module

echo Disabling SysMain Superfetch...
sc stop "SysMain"
sc config "SysMain" start= disabled
echo SysMain Superfetch disabled successfully.
