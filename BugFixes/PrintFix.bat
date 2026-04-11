@echo off

net stop spooler
sc config spooler start= auto
del /Q /F /S "%systemroot%\System32\Spool\Printers\*.*"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Print" /v "SpoolerPriority" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows NT\CurrentVersion\Windows" /v "LegacyDefaultPrinterMode" /t REG_DWORD /d 1 /f
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Print\Printers" /v "PendingDeletion" /f 2>nul
net start spooler
shutdown /r /t 5
