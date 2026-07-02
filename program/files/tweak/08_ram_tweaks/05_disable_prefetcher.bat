@echo off
REM Disable Prefetcher
REM Platinum+ Optimizer - RAM Tweaks Module

echo Disabling prefetcher...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f
echo Prefetcher disabled successfully.
