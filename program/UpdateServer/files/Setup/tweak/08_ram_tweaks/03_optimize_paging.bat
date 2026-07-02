@echo off
REM Optimize Paging Executive
REM Platinum+ Optimizer - RAM Tweaks Module

echo Optimizing paging executive...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargePageMinimum /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SystemPages /t REG_DWORD /d 0 /f
echo Paging executive optimized successfully.
