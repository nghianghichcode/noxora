@echo off
setlocal EnableDelayedExpansion
title Slow internet fix by @Aledect
color 0a

timeout /t 3 /nobreak >nul

:: BASE KEY
set "KROOT=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"

:: POLICY CLEAN
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /f >nul 2>&1
reg delete "HKLM\System\CurrentControlSet\Services\Dnscache\Parameters" /v DisableCoalescing /f >nul 2>&1

:: FIRST RESET
ipconfig /flushdns >nul
arp -d * >nul 2>&1

:: ADAPTER WALK
for /f "delims=" %%X in ('reg query "%KROOT%" /s /v "*SpeedDuplex" ^| find "HKEY"') do (

 :: WAKE
 reg delete "%%X" /v "WakeOnSlot" /f >nul 2>&1
 reg delete "%%X" /v "*WakeOnMagicPacket" /f >nul 2>&1
 reg delete "%%X" /v "WakeOn" /f >nul 2>&1

 :: EEE
 reg delete "%%X" /v "EnableGreenEthernet" /f >nul 2>&1
 reg delete "%%X" /v "*EEE" /f >nul 2>&1

 :: POWER
 reg delete "%%X" /v "EnablePME" /f >nul 2>&1
 reg delete "%%X" /v "*DeviceSleepOnDisconnect" /f >nul 2>&1

 :: ASPM
 reg delete "%%X" /v "ASPM" /f >nul 2>&1
 reg delete "%%X" /v "EnableAspm" /f >nul 2>&1

 :: WAKE EXTRA
 reg delete "%%X" /v "WakeOnMagicPacketFromS5" /f >nul 2>&1
 reg delete "%%X" /v "*WakeOnPattern" /f >nul 2>&1

 :: MORE POWER
 reg delete "%%X" /v "PowerSavingMode" /f >nul 2>&1
 reg delete "%%X" /v "EnablePowerManagement" /f >nul 2>&1

 :: DYNAMIC
 reg delete "%%X" /v "*EnableDynamicPowerGating" /f >nul 2>&1
 reg delete "%%X" /v "DynamicPowerGating" /f >nul 2>&1

 :: MISC
 reg delete "%%X" /v "LogLinkStateEvent" /f >nul 2>&1
 reg delete "%%X" /v "PnPCapabilities" /f >nul 2>&1
 reg delete "%%X" /v "PowerDownPll" /f >nul 2>&1

 :: MORE EEE
 reg delete "%%X" /v "AdvancedEEE" /f >nul 2>&1
 reg delete "%%X" /v "GigaLite" /f >nul 2>&1

 :: SLEEP
 reg delete "%%X" /v "*SelectiveSuspend" /f >nul 2>&1
 reg delete "%%X" /v "EnableD3ColdInS0" /f >nul 2>&1

 :: WAKE REST
 reg delete "%%X" /v "WakeOnLink" /f >nul 2>&1
 reg delete "%%X" /v "WakeFromPowerOff" /f >nul 2>&1
 reg delete "%%X" /v "WakeUpModeCap" /f >nul 2>&1

 :: SAVERS
 reg delete "%%X" /v "*NicAutoPowerSaver" /f >nul 2>&1
 reg delete "%%X" /v "SavePowerNowEnabled" /f >nul 2>&1
 reg delete "%%X" /v "ReduceSpeedOnPowerDown" /f >nul 2>&1
)

:: MORE POLICY
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\Local" /v fDisablePowerManagement /f >nul 2>&1

:: RESET STACK
netsh winsock reset >nul
netsh int ip reset >nul
netsh int ipv6 reset >nul
netsh advfirewall reset >nul
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1

echo.
echo Completed.
timeout /t 3 /nobreak >nul
shutdown /r /t 1
