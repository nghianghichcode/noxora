@echo off
REM Optimize TCP Window Size
REM Platinum+ Optimizer - Network Tweaks Module

echo Optimizing TCP window size...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v GlobalMaxTcpWindowSize /t REG_DWORD /d 8760 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpWindowSize /t REG_DWORD /d 8760 /f
echo TCP window size optimized successfully.
