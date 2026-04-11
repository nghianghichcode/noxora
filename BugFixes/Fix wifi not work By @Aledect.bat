@echo off
title Fix wifi not work By @Aledect
color 0a

timeout /t 3 /nobreak >nul

:: SERVICES
sc config Dhcp start= auto
sc config WlanSvc start= auto
sc config NlaSvc start= auto
sc config nsi start= auto
sc config DPS start= auto
sc config lmhosts start= auto
sc config LanmanWorkstation start= demand
sc config Netman start= demand
sc config ndu start= demand
sc config Wcmsvc start= auto
sc config RmSvc start= auto
sc config WdiServiceHost start= demand
sc config WwanSvc start= demand
sc config NcbService start= demand
sc config netprofm start= demand
sc config Winmgmt start= auto

:: REGISTRY
reg add "HKLM\System\CurrentControlSet\Services\BFE" /v Start /t REG_DWORD /d 2 /f
reg add "HKLM\System\CurrentControlSet\Services\Dnscache" /v Start /t REG_DWORD /d 2 /f
reg add "HKLM\System\CurrentControlSet\Services\WinHttpAutoProxySvc" /v Start /t REG_DWORD /d 3 /f
reg add "HKLM\Software\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator" /v NoActiveProbe /t REG_DWORD /d 0 /f
reg add "HKLM\System\CurrentControlSet\Services\NlaSvc\Parameters\Internet" /v EnableActiveProbing /t REG_DWORD /d 1 /f

:: TASKS
schtasks /change /tn "Microsoft\Windows\WCM\WiFiTask" /enable
schtasks /change /tn "Microsoft\Windows\WlanSvc\CDSSync" /enable
schtasks /change /tn "Microsoft\Windows\NlaSvc\WiFiTask" /enable
schtasks /change /tn "Microsoft\Windows\DUSM\dusmtask" /enable

:: START
net start Dhcp
net start nsi
net start DPS
net start NlaSvc
net start Wcmsvc
net start RmSvc

:: ADAPTER RESET
for /L %%i in (0,1,5) do (
wmic path win32_networkadapter where index=%%i call disable
)
timeout /t 2 >nul
for /L %%i in (0,1,5) do (
wmic path win32_networkadapter where index=%%i call enable
)

:: NETWORK CLEAN
arp -d *
route -f
nbtstat -R
nbtstat -RR
netcfg -d
netsh winsock reset
netsh int ip reset
netsh int tcp reset
netsh int 6to4 reset all
netsh int teredo reset all
netsh int isatap reset all
netsh int httpstunnel reset all
netsh int portproxy reset all
netsh branchcache reset

:: IP
ipconfig /release
ipconfig /renew

echo.
echo Completed.
timeout /t 3 /nobreak >nul
shutdown /r /t 1
