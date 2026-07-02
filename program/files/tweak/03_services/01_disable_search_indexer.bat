@echo off
REM Disable Windows Search Indexer
REM Platinum+ Optimizer - Services Module

echo Disabling Windows Search Indexer...
sc stop "WSearch"
sc config "WSearch" start= disabled
echo Windows Search Indexer disabled successfully.
