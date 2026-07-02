@echo off
REM Reset Network Adapters and TCP/IP Stack
REM Platinum+ Optimizer - Bugfix Module

echo Resetting network adapters and TCP/IP stack...
netsh winsock reset
netsh int ip reset
ipconfig /release
ipconfig /renew
ipconfig /flushdns
echo Network adapters and TCP/IP stack reset successfully.
