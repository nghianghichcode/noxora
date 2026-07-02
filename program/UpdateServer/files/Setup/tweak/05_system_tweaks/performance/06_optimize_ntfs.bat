@echo off
REM Optimize NTFS Parameters
REM Platinum+ Optimizer - System Tweaks Module

echo Optimizing NTFS parameters...
fsutil behavior set disable8dot3 1
fsutil behavior set disableencryption 1
fsutil behavior set mftzone 2
echo NTFS parameters optimized successfully.
