@echo off
REM Rebuild Windows Icon Cache
REM Platinum+ Optimizer - Bugfix Module

echo Rebuilding Windows icon cache...
taskkill /f /im explorer.exe
cd /d %userprofile%\AppData\Local
del /f /s /q IconCache.db
cd /d %localappdata%\Microsoft\Windows\Explorer
del /f /s /q iconcache*.db
start explorer.exe
echo Icon cache rebuilt successfully.
