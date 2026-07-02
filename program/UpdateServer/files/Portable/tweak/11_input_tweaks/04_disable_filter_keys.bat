@echo off
REM Disable Filter Keys
REM Platinum+ Optimizer - Input Tweaks Module

echo Disabling filter keys...
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_DWORD /d 122 /f
echo Filter keys disabled successfully.
