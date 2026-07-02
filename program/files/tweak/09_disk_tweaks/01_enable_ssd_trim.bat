@echo off
REM Enable SSD TRIM Optimization
REM Platinum+ Optimizer - Disk Tweaks Module

echo Enabling SSD TRIM optimization...
fsutil behavior set DisableDeleteNotify 0
echo SSD TRIM optimization enabled successfully.
