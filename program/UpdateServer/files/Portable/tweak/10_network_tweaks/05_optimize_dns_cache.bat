@echo off
REM Optimize DNS Cache
REM Platinum+ Optimizer - Network Tweaks Module

echo Optimizing DNS cache...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheTtl /t REG_DWORD /d 86400 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxNegativeCacheTtl /t REG_DWORD /d 0 /f
ipconfig /flushdns
echo DNS cache optimized successfully.
