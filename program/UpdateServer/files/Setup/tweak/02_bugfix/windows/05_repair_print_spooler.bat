@echo off
REM Repair Print Spooler Service
REM Platinum+ Optimizer - Bugfix Module

echo Repairing print spooler service...
net stop spooler
del /f /s /q %systemroot%\System32\spool\printers\*.*
net start spooler
echo Print spooler service repaired successfully.
