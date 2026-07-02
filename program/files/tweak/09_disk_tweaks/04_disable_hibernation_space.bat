@echo off
REM Disable Hibernation Reclaim Space
REM Platinum+ Optimizer - Disk Tweaks Module

echo Disabling hibernation to reclaim space...
powercfg -h off
echo Hibernation disabled and space reclaimed successfully.
