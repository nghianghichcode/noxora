@echo off
REM Enable Large System Cache
REM Platinum+ Optimizer - RAM Tweaks Module

echo Enabling large system cache...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f
echo Large system cache enabled successfully.
