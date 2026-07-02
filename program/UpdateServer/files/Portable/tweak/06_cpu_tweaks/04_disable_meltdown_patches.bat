@echo off
REM Disable CPU Meltdown Patches
REM Platinum+ Optimizer - CPU Tweaks Module

echo Disabling CPU meltdown patches...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f
echo CPU meltdown patches disabled successfully.
