@echo off
REM Disable Search Indexing
REM Platinum+ Optimizer - Disk Tweaks Module

echo Disabling search indexing...
sc stop "WSearch"
sc config "WSearch" start= disabled
echo Search indexing disabled successfully.
