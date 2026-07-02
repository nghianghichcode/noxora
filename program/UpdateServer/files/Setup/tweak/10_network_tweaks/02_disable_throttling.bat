@echo off
REM Disable Network Throttling
REM Platinum+ Optimizer - Network Tweaks Module

echo Disabling network throttling...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f
echo Network throttling disabled successfully.
