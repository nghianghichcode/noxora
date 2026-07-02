@echo off
REM Blender Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Blender performance tweaks...
reg add "HKCU\Software\Blender Foundation" /v "High Priority" /t REG_DWORD /d 1 /f
echo Blender tweaks applied successfully.
