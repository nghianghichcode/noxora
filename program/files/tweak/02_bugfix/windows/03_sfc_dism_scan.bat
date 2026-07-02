@echo off
REM SFC and DISM System Integrity Scan
REM Platinum+ Optimizer - Bugfix Module

echo Running DISM scan...
DISM /Online /Cleanup-Image /RestoreHealth
echo Running SFC scan...
sfc /scannow
echo System integrity scan completed.
