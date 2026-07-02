@echo off
REM Minecraft Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Minecraft performance tweaks...
reg add "HKCU\Software\Mojang\Minecraft" /v "High Priority" /t REG_DWORD /d 1 /f
echo Minecraft tweaks applied successfully.
