@echo off
REM Epic Games Launcher Performance Tweaks
REM Platinum+ Optimizer - Game Performance Module

echo Applying Epic Games Launcher performance tweaks...
reg add "HKCU\Software\Epic Games\EpicGamesLauncher" /v "High Priority" /t REG_DWORD /d 1 /f
echo Epic Games Launcher tweaks applied successfully.
