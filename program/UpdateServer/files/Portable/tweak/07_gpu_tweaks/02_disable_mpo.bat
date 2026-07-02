@echo off
REM Disable Multi-Plane Overlay (MPO)
REM Platinum+ Optimizer - GPU Tweaks Module

echo Disabling multi-plane overlay...
reg add "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v OverlayTestMode /t REG_DWORD /d 5 /f
echo Multi-plane overlay disabled successfully.
