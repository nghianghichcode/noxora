@echo off
REM Disable NTFS Last Access Timestamp
REM Platinum+ Optimizer - Disk Tweaks Module

echo Disabling NTFS last access timestamp...
fsutil behavior set disablelastaccess 1
echo NTFS last access timestamp disabled successfully.
