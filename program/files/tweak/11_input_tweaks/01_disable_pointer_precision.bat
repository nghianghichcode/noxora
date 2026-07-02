@echo off
REM Disable Enhance Pointer Precision
REM Platinum+ Optimizer - Input Tweaks Module

echo Disabling enhance pointer precision...
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 0 /f
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0 /f
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0 /f
echo Enhance pointer precision disabled successfully.
