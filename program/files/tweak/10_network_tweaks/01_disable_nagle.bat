@echo off
REM Disable Nagle's Algorithm
REM Platinum+ Optimizer - Network Tweaks Module

echo Disabling Nagle's algorithm...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpAckFrequency /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TCPNoDelay /t REG_DWORD /d 1 /f
echo Nagle's algorithm disabled successfully.
