@echo off
REM Clear Temp Files on Boot
REM Platinum+ Optimizer - System Tweaks Module

echo Clearing temporary files...
del /f /s /q %temp%\*
del /f /s /q C:\Windows\Temp\*
echo Temporary files cleared successfully.
