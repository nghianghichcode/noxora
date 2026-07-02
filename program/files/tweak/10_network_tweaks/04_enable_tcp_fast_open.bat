@echo off
REM Enable TCP Fast Open
REM Platinum+ Optimizer - Network Tweaks Module

echo Enabling TCP Fast Open...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableFastOpen /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableFastOpenFallback /t REG_DWORD /d 1 /f
echo TCP Fast Open enabled successfully.
