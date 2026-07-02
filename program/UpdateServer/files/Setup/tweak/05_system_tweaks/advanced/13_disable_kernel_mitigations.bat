@echo off
REM Disable Kernel Mitigations
REM Platinum+ Optimizer - System Tweaks Module

echo Disabling kernel mitigations...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f
echo Kernel mitigations disabled successfully.
