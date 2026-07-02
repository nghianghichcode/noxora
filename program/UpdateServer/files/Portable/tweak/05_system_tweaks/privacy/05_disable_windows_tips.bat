@echo off
REM Disable Windows Tips and Suggestions
REM Platinum+ Optimizer - System Tweaks Module

echo Disabling Windows tips and suggestions...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent /t REG_DWORD /d 0 /f
echo Windows tips and suggestions disabled successfully.
