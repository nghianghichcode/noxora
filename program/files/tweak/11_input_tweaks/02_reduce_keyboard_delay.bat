@echo off
REM Reduce Keyboard Repeat Delay
REM Platinum+ Optimizer - Input Tweaks Module

echo Reducing keyboard repeat delay...
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v AutoRepeatDelay /t REG_SZ /d 200 /f
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v AutoRepeatRate /t REG_SZ /d 15 /f
echo Keyboard repeat delay reduced successfully.
