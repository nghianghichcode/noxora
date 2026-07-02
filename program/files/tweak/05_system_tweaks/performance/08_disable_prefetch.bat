@echo off
REM Disable Prefetch and Superfetch
REM Platinum+ Optimizer - System Tweaks Module

echo Disabling prefetch and superfetch...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f
echo Prefetch and superfetch disabled successfully.
