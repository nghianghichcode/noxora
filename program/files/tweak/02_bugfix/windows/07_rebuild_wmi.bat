@echo off
REM Rebuild WMI Repository
REM Platinum+ Optimizer - Bugfix Module

echo Rebuilding WMI repository...
winmgmt /salvagerepository %windir%\System32\wbem
winmgmt /verifyrepository %windir%\System32\wbem
if %errorlevel% equ 0 (
    echo WMI repository is consistent.
) else (
    winmgmt /resetrepository %windir%\System32\wbem
)
echo WMI repository rebuild completed.
