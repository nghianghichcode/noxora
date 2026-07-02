@echo off
REM Disable Memory Compression
REM Platinum+ Optimizer - RAM Tweaks Module

echo Disabling memory compression...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableCompression /t REG_DWORD /d 0 /f
echo Memory compression disabled successfully.
