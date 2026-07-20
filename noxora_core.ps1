#requires -Version 5.1
# ==============================================================================
# NOXORA OPTIMIZER - SAFE SYSTEM ADMINISTRATION EDITION
# Purpose: audit, diagnostics, reversible tuning and local reporting.
# This script does NOT download payloads, create persistence, hide processes,
# disable security products, exfiltrate data, mine crypto, or perform botnet tasks.
# ==============================================================================

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

try {
    [System.Diagnostics.Process]::GetCurrentProcess().PriorityClass =
        [System.Diagnostics.ProcessPriorityClass]::AboveNormal
} catch {}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# ------------------------------------------------------------------------------
# Application paths and global state
# ------------------------------------------------------------------------------
$script:AppRoot        = Join-Path $env:ProgramData "NoxoraOptimizer"
$script:LogRoot        = Join-Path $script:AppRoot "Logs"
$script:StateRoot      = Join-Path $script:AppRoot "State"
$script:CredentialFile = Join-Path $script:AppRoot "admin.credential.json"
$script:LatestState    = Join-Path $script:StateRoot "latest-state.json"
$script:LogFile        = Join-Path $script:LogRoot ("noxora-{0}.log" -f (Get-Date -Format "yyyyMMdd"))
$script:IsAuthenticated = $false
$script:SetupComplete   = $false
$script:LoginAttempts   = 0
$script:txtConsole      = $null
$script:txtSummary      = $null
$script:windowMain      = $null
$script:LastReport      = [ordered]@{
    Application = "Noxora Optimizer"
    Version     = "2.0-safe"
    GeneratedAt = (Get-Date).ToString("o")
}

foreach ($folder in @($script:AppRoot, $script:LogRoot, $script:StateRoot)) {
    if (-not (Test-Path -LiteralPath $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}

# ------------------------------------------------------------------------------
# Safety and privilege checks
# ------------------------------------------------------------------------------
function Test-NoxoraAdministrator {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-NoxoraAdministrator)) {
    if ($PSCommandPath) {
        try {
            Start-Process -FilePath "powershell.exe" `
                -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
                -Verb RunAs
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Noxora requires Administrator rights.",
                "Noxora Optimizer",
                "OK",
                "Warning"
            ) | Out-Null
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "Open PowerShell as Administrator, then run Noxora again.",
            "Noxora Optimizer",
            "OK",
            "Warning"
        ) | Out-Null
    }
    exit
}

$createdNew = $false
$script:Mutex = New-Object System.Threading.Mutex(
    $true,
    "Global\NoxoraOptimizer.SafeEdition",
    [ref]$createdNew
)
if (-not $createdNew) {
    [System.Windows.Forms.MessageBox]::Show(
        "Noxora is already running.",
        "Noxora Optimizer",
        "OK",
        "Information"
    ) | Out-Null
    exit
}

# ------------------------------------------------------------------------------
# Logging and UI helpers
# ------------------------------------------------------------------------------
function Write-NoxoraLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"

    try {
        Add-Content `
            -LiteralPath $script:LogFile `
            -Value $line `
            -Encoding UTF8
    }
    catch {
        # Lỗi ghi log không được làm ứng dụng dừng.
    }

    if ($null -ne $script:txtConsole) {
        $appendAction = [System.Action]{
            $shortTime = Get-Date -Format "HH:mm:ss"

            $script:txtConsole.AppendText(
                "[$shortTime][$Level] $Message`r`n"
            )

            $script:txtConsole.ScrollToEnd()
        }

        if ($script:txtConsole.Dispatcher.CheckAccess()) {
            $appendAction.Invoke()
        }
        else {
            $script:txtConsole.Dispatcher.Invoke(
                $appendAction
            ) | Out-Null
        }
    }
}

function Set-NoxoraSummary {
    param([string]$Text)
    if ($null -ne $script:txtSummary) {
        $script:txtSummary.Text = $Text
    }
}

function Invoke-NoxoraUiPump {
    if ($null -ne $script:windowMain) {
        $script:windowMain.Dispatcher.Invoke(
            [Action]{},
            [Windows.Threading.DispatcherPriority]::Background
        )
    }
}

function Invoke-NoxoraAction {
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [scriptblock]$Action,

        [scriptblock]$OnSuccess
    )

    try {
        $script:windowMain.Cursor = [System.Windows.Input.Cursors]::Wait
        Write-NoxoraLog $Title "INFO"
        Invoke-NoxoraUiPump

        $result = & $Action

        if ($null -ne $OnSuccess) {
            & $OnSuccess $result
        }

        Write-NoxoraLog "$Title - completed." "SUCCESS"
    } catch {
        $message = $_.Exception.Message
        Write-NoxoraLog "$Title - failed: $message" "ERROR"
        [System.Windows.Forms.MessageBox]::Show(
            $message,
            "Noxora Optimizer",
            "OK",
            "Error"
        ) | Out-Null
    } finally {
        $script:windowMain.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
}

# ------------------------------------------------------------------------------
# Local credential protection using Windows DPAPI
# ------------------------------------------------------------------------------
function ConvertFrom-NoxoraSecureString {
    param([Security.SecureString]$SecureString)

    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

function Save-NoxoraCredential {
    param(
        [Parameter(Mandatory)]
        [string]$UserName,

        [Parameter(Mandatory)]
        [string]$PlainPassword
    )

    $securePassword = ConvertTo-SecureString -String $PlainPassword -AsPlainText -Force
    $encryptedSecret = ConvertFrom-SecureString -SecureString $securePassword

    [pscustomobject]@{
        UserName  = $UserName.Trim()
        Secret    = $encryptedSecret
        CreatedAt = (Get-Date).ToString("o")
        Scope     = "Windows-DPAPI-CurrentUser"
    } |
        ConvertTo-Json -Depth 4 |
        Set-Content -LiteralPath $script:CredentialFile -Encoding UTF8
}

function Test-NoxoraCredential {
    param(
        [Parameter(Mandatory)]
        [string]$UserName,

        [Parameter(Mandatory)]
        [string]$PlainPassword
    )

    if (-not (Test-Path -LiteralPath $script:CredentialFile)) {
        return $false
    }

    try {
        $stored = Get-Content -LiteralPath $script:CredentialFile -Raw | ConvertFrom-Json
        if ($stored.UserName -cne $UserName.Trim()) {
            return $false
        }

        $savedSecure = ConvertTo-SecureString -String $stored.Secret
        $savedPlain  = ConvertFrom-NoxoraSecureString -SecureString $savedSecure

        if ($savedPlain.Length -ne $PlainPassword.Length) {
            return $false
        }

        $difference = 0
        for ($i = 0; $i -lt $savedPlain.Length; $i++) {
            $difference = $difference -bor (
                [int][char]$savedPlain[$i] -bxor [int][char]$PlainPassword[$i]
            )
        }
        return ($difference -eq 0)
    } catch {
        Write-NoxoraLog "Credential validation error: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ------------------------------------------------------------------------------
# First-run administrator setup
# ------------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $script:CredentialFile)) {
    $xamlSetup = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Noxora First Run Setup"
        Height="430" Width="470"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        WindowStartupLocation="CenterScreen"
        Topmost="True">
    <Border Background="#181825"
            CornerRadius="16"
            BorderBrush="#89b4fa"
            BorderThickness="1.5"
            Margin="16">
        <Grid Margin="28">
            <Grid.RowDefinitions>
                <RowDefinition Height="52"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="48"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="48"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="48"/>
                <RowDefinition Height="58"/>
            </Grid.RowDefinitions>

            <TextBlock Grid.Row="0"
                       Text="NOXORA FIRST-RUN ADMIN SETUP"
                       Foreground="#89b4fa"
                       FontSize="17"
                       FontWeight="Black"
                       HorizontalAlignment="Center"
                       VerticalAlignment="Center"/>

            <TextBlock Grid.Row="1" Text="ADMIN USERNAME"
                       Foreground="#a6adc8" FontWeight="Bold" FontSize="11"/>
            <TextBox Name="SetupUser" Grid.Row="2"
                     Background="#11111b" Foreground="#cdd6f4"
                     BorderBrush="#45475a" Padding="12,9"
                     FontSize="14"/>

            <TextBlock Grid.Row="3" Text="PASSWORD (MINIMUM 10 CHARACTERS)"
                       Foreground="#a6adc8" FontWeight="Bold" FontSize="11"
                       Margin="0,12,0,0"/>
            <PasswordBox Name="SetupPass" Grid.Row="4"
                         Background="#11111b" Foreground="#cdd6f4"
                         BorderBrush="#45475a" Padding="12,9"
                         FontSize="14"/>

            <TextBlock Grid.Row="5" Text="CONFIRM PASSWORD"
                       Foreground="#a6adc8" FontWeight="Bold" FontSize="11"
                       Margin="0,12,0,0"/>
            <PasswordBox Name="SetupConfirm" Grid.Row="6"
                         Background="#11111b" Foreground="#cdd6f4"
                         BorderBrush="#45475a" Padding="12,9"
                         FontSize="14"/>

            <Button Name="SetupCreate" Grid.Row="7"
                    Content="CREATE LOCAL ADMIN PROFILE"
                    Background="#89b4fa"
                    Foreground="#11111b"
                    BorderThickness="0"
                    FontWeight="Black"
                    FontSize="13"
                    Margin="0,16,0,0"
                    Cursor="Hand"/>
        </Grid>
    </Border>
</Window>
"@

    $setupReader = New-Object System.Xml.XmlNodeReader ([xml]$xamlSetup)
    $setupWindow = [Windows.Markup.XamlReader]::Load($setupReader)

    $setupUser    = $setupWindow.FindName("SetupUser")
    $setupPass    = $setupWindow.FindName("SetupPass")
    $setupConfirm = $setupWindow.FindName("SetupConfirm")
    $setupCreate  = $setupWindow.FindName("SetupCreate")

    $setupCreate.Add_Click({
        $user = $setupUser.Text.Trim()
        $pass = $setupPass.Password
        $confirm = $setupConfirm.Password

        if ([string]::IsNullOrWhiteSpace($user)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Username cannot be empty.",
                "Noxora Setup",
                "OK",
                "Warning"
            ) | Out-Null
            return
        }

        if ($pass.Length -lt 10) {
            [System.Windows.Forms.MessageBox]::Show(
                "Password must contain at least 10 characters.",
                "Noxora Setup",
                "OK",
                "Warning"
            ) | Out-Null
            return
        }

        if ($pass -cne $confirm) {
            [System.Windows.Forms.MessageBox]::Show(
                "Password confirmation does not match.",
                "Noxora Setup",
                "OK",
                "Warning"
            ) | Out-Null
            return
        }

        Save-NoxoraCredential -UserName $user -PlainPassword $pass
        $script:SetupComplete = $true
        $setupWindow.Close()
    })

    $setupWindow.ShowDialog() | Out-Null

    if (-not $script:SetupComplete) {
        exit
    }
}

# ------------------------------------------------------------------------------
# Login screen
# ------------------------------------------------------------------------------
$xamlLogin = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Noxora Secure Access"
        Height="360" Width="450"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        WindowStartupLocation="CenterScreen"
        Topmost="True">
    <Border Background="#181825"
            CornerRadius="16"
            BorderBrush="#cba6f7"
            BorderThickness="1.5"
            Margin="16">
        <Border.Effect>
            <DropShadowEffect Color="#cba6f7"
                              BlurRadius="20"
                              ShadowDepth="0"
                              Opacity="0.45"/>
        </Border.Effect>

        <Grid Margin="26">
            <Grid.RowDefinitions>
                <RowDefinition Height="52"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="50"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="50"/>
                <RowDefinition Height="62"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0">
                <TextBlock Text="NOXORA SECURE GATEWAY"
                           Foreground="#cba6f7"
                           FontSize="17"
                           FontWeight="Black"
                           HorizontalAlignment="Center"
                           VerticalAlignment="Center"/>
                <Button Name="BtnExit"
                        Content="X"
                        Width="32"
                        Height="32"
                        HorizontalAlignment="Right"
                        Background="Transparent"
                        Foreground="#f38ba8"
                        BorderThickness="0"
                        FontWeight="Bold"
                        Cursor="Hand"/>
            </Grid>

            <TextBlock Grid.Row="1"
                       Text="LOCAL ADMIN ID"
                       Foreground="#a6adc8"
                       FontSize="11"
                       FontWeight="Bold"/>
            <TextBox Name="TxtUser"
                     Grid.Row="2"
                     Background="#11111b"
                     Foreground="#cdd6f4"
                     BorderBrush="#45475a"
                     Padding="12,9"
                     FontSize="14"/>

            <TextBlock Grid.Row="3"
                       Text="DPAPI-PROTECTED PASSWORD"
                       Foreground="#a6adc8"
                       FontSize="11"
                       FontWeight="Bold"
                       Margin="0,12,0,0"/>
            <PasswordBox Name="TxtPass"
                         Grid.Row="4"
                         Background="#11111b"
                         Foreground="#cdd6f4"
                         BorderBrush="#45475a"
                         Padding="12,9"
                         FontSize="14"/>

            <Button Name="BtnLogin"
                    Grid.Row="5"
                    Content="INITIALIZE SECURE SESSION"
                    Margin="0,16,0,0"
                    Background="#cba6f7"
                    Foreground="#11111b"
                    BorderThickness="0"
                    FontWeight="Black"
                    FontSize="13"
                    Cursor="Hand"/>
        </Grid>
    </Border>
</Window>
"@

$readerLogin = New-Object System.Xml.XmlNodeReader ([xml]$xamlLogin)
$windowLogin = [Windows.Markup.XamlReader]::Load($readerLogin)

$txtUser  = $windowLogin.FindName("TxtUser")
$txtPass  = $windowLogin.FindName("TxtPass")
$btnLogin = $windowLogin.FindName("BtnLogin")
$btnExit  = $windowLogin.FindName("BtnExit")

$btnExit.Add_Click({ $windowLogin.Close() })

$loginAction = {
    $script:LoginAttempts++

    if (Test-NoxoraCredential -UserName $txtUser.Text -PlainPassword $txtPass.Password) {
        $script:IsAuthenticated = $true
        Write-NoxoraLog "Local administrator authenticated." "SUCCESS"
        $windowLogin.Close()
        return
    }

    $remaining = 5 - $script:LoginAttempts
    if ($remaining -le 0) {
        Write-NoxoraLog "Login blocked after five failed attempts." "WARN"
        [System.Windows.Forms.MessageBox]::Show(
            "Too many failed attempts. Noxora will close.",
            "Noxora Security",
            "OK",
            "Error"
        ) | Out-Null
        $windowLogin.Close()
        return
    }

    [System.Windows.Forms.MessageBox]::Show(
        "Unauthorized login. Remaining attempts: $remaining",
        "Noxora Security",
        "OK",
        "Error"
    ) | Out-Null
    $txtPass.Clear()
    $txtPass.Focus()
}

$btnLogin.Add_Click($loginAction)
$txtPass.Add_KeyDown({
    if ($_.Key -eq [System.Windows.Input.Key]::Return) {
        & $loginAction
    }
})

$windowLogin.ShowDialog() | Out-Null
if (-not $script:IsAuthenticated) {
    exit
}

# ------------------------------------------------------------------------------
# Core inventory and audit functions
# ------------------------------------------------------------------------------
function Get-NoxoraSystemInventory {
    $os       = Get-CimInstance Win32_OperatingSystem
    $computer = Get-CimInstance Win32_ComputerSystem
    $cpu      = Get-CimInstance Win32_Processor | Select-Object -First 1
    $bios     = Get-CimInstance Win32_BIOS | Select-Object -First 1
    $gpus     = Get-CimInstance Win32_VideoController
    $logicalDisks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $battery  = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue

    $physicalDisks = @()
    if (Get-Command Get-PhysicalDisk -ErrorAction SilentlyContinue) {
        $physicalDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue |
            Select-Object FriendlyName, MediaType, BusType, HealthStatus,
                OperationalStatus,
                @{Name="SizeGB"; Expression={[math]::Round($_.Size / 1GB, 1)}}
    }

    $temperature = $null
    try {
        $zones = Get-CimInstance `
            -Namespace "root/wmi" `
            -ClassName "MSAcpi_ThermalZoneTemperature" `
            -ErrorAction Stop

        if ($zones) {
            $temperature = $zones | ForEach-Object {
                [math]::Round(($_.CurrentTemperature / 10) - 273.15, 1)
            }
        }
    } catch {
        $temperature = $null
    }

    [pscustomobject]@{
        CollectedAt = (Get-Date).ToString("o")
        Computer = [pscustomobject]@{
            Manufacturer = $computer.Manufacturer
            Model        = $computer.Model
            TotalRAMGB   = [math]::Round($computer.TotalPhysicalMemory / 1GB, 1)
        }
        OperatingSystem = [pscustomobject]@{
            Caption      = $os.Caption
            Version      = $os.Version
            BuildNumber  = $os.BuildNumber
            Architecture = $os.OSArchitecture
            LastBoot     = $os.LastBootUpTime
            FreeRAMGB    = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
        }
        Processor = [pscustomobject]@{
            Name             = $cpu.Name.Trim()
            Cores            = $cpu.NumberOfCores
            LogicalProcessors = $cpu.NumberOfLogicalProcessors
            MaxClockMHz      = $cpu.MaxClockSpeed
            CurrentClockMHz  = $cpu.CurrentClockSpeed
            LoadPercent      = $cpu.LoadPercentage
        }
        Graphics = @(
            $gpus | Select-Object Name, DriverVersion,
                @{Name="AdapterRAMGB"; Expression={
                    if ($_.AdapterRAM) {
                        [math]::Round($_.AdapterRAM / 1GB, 1)
                    } else {
                        $null
                    }
                }}
        )
        BIOS = [pscustomobject]@{
            Manufacturer = $bios.Manufacturer
            Version      = ($bios.SMBIOSBIOSVersion -join ", ")
            ReleaseDate  = $bios.ReleaseDate
            SerialNumber = $bios.SerialNumber
        }
        LogicalDisks = @(
            $logicalDisks | Select-Object DeviceID, VolumeName, FileSystem,
                @{Name="SizeGB"; Expression={[math]::Round($_.Size / 1GB, 1)}},
                @{Name="FreeGB"; Expression={[math]::Round($_.FreeSpace / 1GB, 1)}},
                @{Name="FreePercent"; Expression={
                    if ($_.Size -gt 0) {
                        [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
                    } else {
                        0
                    }
                }}
        )
        PhysicalDisks = @($physicalDisks)
        Battery = @(
            $battery | Select-Object Name, Status, EstimatedChargeRemaining,
                EstimatedRunTime
        )
        ThermalZoneCelsius = @($temperature)
    }
}

function Get-NoxoraProcessAudit {
    $perf = Get-CimInstance Win32_PerfFormattedData_PerfProc_Process |
        Where-Object {
            $_.IDProcess -gt 0 -and
            $_.Name -notin @("_Total", "Idle")
        } |
        Sort-Object PercentProcessorTime -Descending |
        Select-Object -First 20

    $rows = foreach ($item in $perf) {
        $process = Get-Process -Id $item.IDProcess -ErrorAction SilentlyContinue
        $path = $null
        $signature = "Unknown"

        if ($process) {
            try { $path = $process.Path } catch {}
        }

        if ($path -and (Test-Path -LiteralPath $path)) {
            try {
                $signature = (Get-AuthenticodeSignature -FilePath $path).Status.ToString()
            } catch {
                $signature = "CheckFailed"
            }
        }

        [pscustomobject]@{
            PID       = $item.IDProcess
            Name      = $item.Name
            CPU       = $item.PercentProcessorTime
            RAMMB     = [math]::Round($item.WorkingSetPrivate / 1MB, 1)
            Threads   = $item.ThreadCount
            Handles   = $item.HandleCount
            Signature = $signature
            Path      = $path
        }
    }

    return @($rows)
}

function Get-NoxoraRegistryStartupEntries {
    $targets = @(
        @{ Scope = "CurrentUser"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" },
        @{ Scope = "CurrentUserOnce"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" },
        @{ Scope = "LocalMachine"; Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" },
        @{ Scope = "LocalMachineOnce"; Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" },
        @{ Scope = "LocalMachine32"; Path = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" }
    )

    $entries = foreach ($target in $targets) {
        if (Test-Path -LiteralPath $target.Path) {
            $item = Get-ItemProperty -LiteralPath $target.Path
            foreach ($property in $item.PSObject.Properties) {
                if ($property.Name -notmatch "^PS") {
                    [pscustomobject]@{
                        Scope   = $target.Scope
                        Name    = $property.Name
                        Command = [string]$property.Value
                    }
                }
            }
        }
    }

    return @($entries)
}

function Get-NoxoraStartupAudit {
    $startupFolders = @(
        [Environment]::GetFolderPath("Startup"),
        [Environment]::GetFolderPath("CommonStartup")
    )

    $startupFiles = foreach ($folder in $startupFolders) {
        if ($folder -and (Test-Path -LiteralPath $folder)) {
            Get-ChildItem -LiteralPath $folder -Force -ErrorAction SilentlyContinue |
                Select-Object Name, FullName, LastWriteTime
        }
    }

    $scheduled = @()
    if (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue) {
        $scheduled = Get-ScheduledTask -ErrorAction SilentlyContinue |
            Where-Object {
                $_.TaskPath -notlike "\Microsoft\*" -and
                $_.State -ne "Disabled"
            } |
            Select-Object -First 60 TaskName, TaskPath, State, Author
    }

    [pscustomobject]@{
        RegistryEntries = @(Get-NoxoraRegistryStartupEntries)
        StartupFiles    = @($startupFiles)
        ScheduledTasks  = @($scheduled)
    }
}

function Get-NoxoraServiceAudit {
    $services = Get-CimInstance Win32_Service

    $autoStopped = $services |
        Where-Object {
            $_.StartMode -eq "Auto" -and
            $_.State -eq "Stopped"
        } |
        Select-Object Name, DisplayName, StartMode, State, StartName, PathName

    $thirdPartyAuto = $services |
        Where-Object {
            $_.StartMode -eq "Auto" -and
            $_.PathName -and
            $_.PathName -notmatch "\\Windows\\System32\\" -and
            $_.PathName -notmatch "svchost\.exe"
        } |
        Select-Object Name, DisplayName, State, StartName, PathName

    [pscustomobject]@{
        AutomaticButStopped = @($autoStopped)
        ThirdPartyAutomatic = @($thirdPartyAuto)
        TotalServices       = @($services).Count
        RunningServices     = @($services | Where-Object State -eq "Running").Count
    }
}

function Get-NoxoraNetworkAudit {
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue |
        Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress,
            ifIndex

    $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
        Sort-Object RouteMetric, InterfaceMetric |
        Select-Object -First 1

    $gatewayReachable = $false
    if ($route -and $route.NextHop -and $route.NextHop -ne "0.0.0.0") {
        $gatewayReachable = Test-Connection `
            -ComputerName $route.NextHop `
            -Count 1 `
            -Quiet `
            -ErrorAction SilentlyContinue
    }

    $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.ServerAddresses.Count -gt 0 } |
        Select-Object InterfaceAlias, ServerAddresses

    $dnsResolution = $false
    if (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue) {
        try {
            Resolve-DnsName "example.com" -Type A -QuickTimeout -ErrorAction Stop |
                Select-Object -First 1 | Out-Null
            $dnsResolution = $true
        } catch {
            $dnsResolution = $false
        }
    }

    $established = 0
    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        $established = @(
            Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
        ).Count
    }

    [pscustomobject]@{
        Adapters               = @($adapters)
        DefaultGateway         = if ($route) { $route.NextHop } else { $null }
        DefaultInterfaceIndex  = if ($route) { $route.ifIndex } else { $null }
        GatewayReachable       = $gatewayReachable
        DnsServers             = @($dnsServers)
        DnsResolution          = $dnsResolution
        EstablishedConnections = $established
    }
}

function Get-NoxoraSecurityAudit {
    $firewall = @()
    if (Get-Command Get-NetFirewallProfile -ErrorAction SilentlyContinue) {
        $firewall = Get-NetFirewallProfile -ErrorAction SilentlyContinue |
            Select-Object Name, Enabled, DefaultInboundAction,
                DefaultOutboundAction
    }

    $defender = $null
    if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
        try {
            $mp = Get-MpComputerStatus
            $defender = [pscustomobject]@{
                AntivirusEnabled          = $mp.AntivirusEnabled
                AntispywareEnabled        = $mp.AntispywareEnabled
                RealTimeProtectionEnabled = $mp.RealTimeProtectionEnabled
                BehaviorMonitorEnabled    = $mp.BehaviorMonitorEnabled
                IoavProtectionEnabled     = $mp.IoavProtectionEnabled
                NISEnabled                = $mp.NISEnabled
                LastQuickScan             = $mp.QuickScanEndTime
                SignatureAgeDays          = $mp.AntivirusSignatureAge
            }
        } catch {
            $defender = [pscustomobject]@{
                Error = $_.Exception.Message
            }
        }
    }

    $uacValue = Get-ItemPropertyValue `
        -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        -Name "EnableLUA" `
        -ErrorAction SilentlyContinue

    $secureBoot = $null
    if (Get-Command Confirm-SecureBootUEFI -ErrorAction SilentlyContinue) {
        try {
            $secureBoot = Confirm-SecureBootUEFI
        } catch {
            $secureBoot = $null
        }
    }

    $bitLocker = @()
    if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
        try {
            $bitLocker = Get-BitLockerVolume -ErrorAction Stop |
                Select-Object MountPoint, VolumeStatus, ProtectionStatus,
                    EncryptionPercentage, EncryptionMethod
        } catch {}
    }

    [pscustomobject]@{
        Firewall   = @($firewall)
        Defender   = $defender
        UACEnabled = ($uacValue -eq 1)
        SecureBoot = $secureBoot
        BitLocker  = @($bitLocker)
    }
}

# ------------------------------------------------------------------------------
# Reversible system-state backup
# ------------------------------------------------------------------------------
function Get-NoxoraActivePowerScheme {
    try {
        $output = (powercfg /getactivescheme 2>&1) -join " "
        if ($output -match "([A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12})") {
            return $Matches[1]
        }
    } catch {}
    return $null
}

function Get-NoxoraRegistryState {
    param(
        [string]$Path,
        [string]$Name
    )

    $exists = $false
    $value = $null

    if (Test-Path -LiteralPath $Path) {
        try {
            $value = Get-ItemPropertyValue -LiteralPath $Path -Name $Name -ErrorAction Stop
            $exists = $true
        } catch {}
    }

    [pscustomobject]@{
        Path   = $Path
        Name   = $Name
        Exists = $exists
        Value  = $value
        Type   = "DWord"
    }
}

function Save-NoxoraSystemState {
    $registryTargets = @(
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_Enabled" },
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"; Name = "AppCaptureEnabled" },
        @{ Path = "HKCU:\SOFTWARE\Microsoft\GameBar"; Name = "AutoGameModeEnabled" },
        @{ Path = "HKCU:\SOFTWARE\Microsoft\GameBar"; Name = "AllowAutoGameMode" }
    )

    $registryState = foreach ($target in $registryTargets) {
        Get-NoxoraRegistryState -Path $target.Path -Name $target.Name
    }

    $state = [pscustomobject]@{
        CreatedAt         = (Get-Date).ToString("o")
        ActivePowerScheme = Get-NoxoraActivePowerScheme
        Registry          = @($registryState)
    }

    $timestampFile = Join-Path $script:StateRoot (
        "state-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss")
    )

    $json = $state | ConvertTo-Json -Depth 8
    $json | Set-Content -LiteralPath $timestampFile -Encoding UTF8
    $json | Set-Content -LiteralPath $script:LatestState -Encoding UTF8

    Write-NoxoraLog "Rollback state saved: $timestampFile" "SUCCESS"
    return $state
}

function New-NoxoraRestorePoint {
    try {
        Checkpoint-Computer `
            -Description ("Noxora Safe Tune {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm")) `
            -RestorePointType "MODIFY_SETTINGS" `
            -ErrorAction Stop
        Write-NoxoraLog "Windows restore point created." "SUCCESS"
        return $true
    } catch {
        Write-NoxoraLog (
            "Restore point was not created. System Protection may be disabled: " +
            $_.Exception.Message
        ) "WARN"
        return $false
    }
}

function Set-NoxoraRegistryDword {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [int]$Value
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty `
        -LiteralPath $Path `
        -Name $Name `
        -Value $Value `
        -PropertyType DWord `
        -Force | Out-Null
}

function Set-NoxoraActivePowerScheme {
    param(
        [Parameter(Mandatory)]
        [string]$Scheme
    )

    $output = & powercfg.exe /setactive $Scheme 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ("powercfg failed: " + (($output | Out-String).Trim()))
    }

    return $true
}

# ------------------------------------------------------------------------------
# Safe optimization profiles
# ------------------------------------------------------------------------------
function Remove-NoxoraOldTempFiles {
    param(
        [string[]]$Paths,
        [int]$OlderThanDays
    )

    $cutoff = (Get-Date).AddDays(-1 * $OlderThanDays)
    [long]$freedBytes = 0
    [int]$removedFiles = 0

    foreach ($path in $Paths) {
        if (-not $path -or -not (Test-Path -LiteralPath $path)) {
            continue
        }

        $files = Get-ChildItem `
            -LiteralPath $path `
            -File `
            -Force `
            -Recurse `
            -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoff }

        foreach ($file in $files) {
            try {
                $length = $file.Length
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                $freedBytes += $length
                $removedFiles++
            } catch {}
        }

        $directories = Get-ChildItem `
            -LiteralPath $path `
            -Directory `
            -Force `
            -Recurse `
            -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending

        foreach ($directory in $directories) {
            try {
                if (-not (Get-ChildItem -LiteralPath $directory.FullName -Force -ErrorAction Stop)) {
                    Remove-Item -LiteralPath $directory.FullName -Force -ErrorAction Stop
                }
            } catch {}
        }
    }

    [pscustomobject]@{
        RemovedFiles = $removedFiles
        FreedMB      = [math]::Round($freedBytes / 1MB, 1)
    }
}

function Invoke-NoxoraSafeOptimize {
    Save-NoxoraSystemState | Out-Null
    $restorePoint = New-NoxoraRestorePoint

    $cleanup = Remove-NoxoraOldTempFiles `
        -Paths @($env:TEMP, (Join-Path $env:windir "Temp")) `
        -OlderThanDays 3

    try {
        $dnsOutput = & ipconfig.exe /flushdns 2>&1
        $dnsFlushed = ($LASTEXITCODE -eq 0)
        if (-not $dnsFlushed) {
            Write-NoxoraLog (
                "DNS flush failed: " + (($dnsOutput | Out-String).Trim())
            ) "WARN"
        }
    } catch {
        $dnsFlushed = $false
    }

    $powerChanged = $false
    try {
        $powerChanged = Set-NoxoraActivePowerScheme -Scheme "SCHEME_MIN"
    } catch {
        Write-NoxoraLog "High Performance power plan is unavailable: $($_.Exception.Message)" "WARN"
    }

    [pscustomobject]@{
        RestorePointCreated = $restorePoint
        TempFilesRemoved    = $cleanup.RemovedFiles
        TempSpaceFreedMB    = $cleanup.FreedMB
        DnsCacheFlushed     = $dnsFlushed
        HighPerformancePlan = $powerChanged
        RestartRequired     = $false
    }
}

function Invoke-NoxoraGameProfile {
    Save-NoxoraSystemState | Out-Null
    $restorePoint = New-NoxoraRestorePoint

    Set-NoxoraRegistryDword `
        -Path "HKCU:\SOFTWARE\Microsoft\GameBar" `
        -Name "AutoGameModeEnabled" `
        -Value 1

    Set-NoxoraRegistryDword `
        -Path "HKCU:\SOFTWARE\Microsoft\GameBar" `
        -Name "AllowAutoGameMode" `
        -Value 1

    Set-NoxoraRegistryDword `
        -Path "HKCU:\System\GameConfigStore" `
        -Name "GameDVR_Enabled" `
        -Value 0

    Set-NoxoraRegistryDword `
        -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" `
        -Name "AppCaptureEnabled" `
        -Value 0

    $powerChanged = $false
    try {
        $powerChanged = Set-NoxoraActivePowerScheme -Scheme "SCHEME_MIN"
    } catch {
        Write-NoxoraLog "High Performance power plan is unavailable: $($_.Exception.Message)" "WARN"
    }

    [pscustomobject]@{
        RestorePointCreated = $restorePoint
        WindowsGameMode     = "Enabled"
        GameDvrCapture      = "Disabled"
        PowerPlanChanged    = $powerChanged
        RestartRequired     = $false
    }
}

function Restore-NoxoraSystemState {
    if (-not (Test-Path -LiteralPath $script:LatestState)) {
        throw "No rollback state was found."
    }

    $state = Get-Content -LiteralPath $script:LatestState -Raw | ConvertFrom-Json

    foreach ($entry in $state.Registry) {
        if ($entry.Exists) {
            Set-NoxoraRegistryDword `
                -Path ([string]$entry.Path) `
                -Name ([string]$entry.Name) `
                -Value ([int]$entry.Value)
        } else {
            if (Test-Path -LiteralPath ([string]$entry.Path)) {
                Remove-ItemProperty `
                    -LiteralPath ([string]$entry.Path) `
                    -Name ([string]$entry.Name) `
                    -ErrorAction SilentlyContinue
            }
        }
    }

    $powerRestored = $false
    if ($state.ActivePowerScheme) {
        try {
            $powerRestored = Set-NoxoraActivePowerScheme `
                -Scheme ([string]$state.ActivePowerScheme)
        } catch {
            Write-NoxoraLog "Power-plan rollback failed: $($_.Exception.Message)" "WARN"
        }
    }

    [pscustomobject]@{
        RestoredFrom       = $state.CreatedAt
        RegistryRestored   = $true
        PowerPlanRestored  = $powerRestored
        RestartRequired    = $false
    }
}

# ------------------------------------------------------------------------------
# Reporting and text formatters
# ------------------------------------------------------------------------------
function Format-NoxoraInventory {
    param($Inventory)

    $gpuText = if ($Inventory.Graphics.Count -gt 0) {
        ($Inventory.Graphics | ForEach-Object {
            "{0} | Driver {1}" -f $_.Name, $_.DriverVersion
        }) -join "`r`n"
    } else {
        "Not detected"
    }

    $diskText = if ($Inventory.LogicalDisks.Count -gt 0) {
        ($Inventory.LogicalDisks | ForEach-Object {
            "{0} {1} GB free / {2} GB ({3}%)" -f
                $_.DeviceID, $_.FreeGB, $_.SizeGB, $_.FreePercent
        }) -join "`r`n"
    } else {
        "Not detected"
    }

    $temperatureText = if ($Inventory.ThermalZoneCelsius.Count -gt 0) {
        ($Inventory.ThermalZoneCelsius -join ", ") + " C"
    } else {
        "Sensor not exposed by firmware"
    }

    return @"
SYSTEM OVERVIEW

Machine:
$($Inventory.Computer.Manufacturer) $($Inventory.Computer.Model)

Operating system:
$($Inventory.OperatingSystem.Caption)
Build $($Inventory.OperatingSystem.BuildNumber) | $($Inventory.OperatingSystem.Architecture)

Processor:
$($Inventory.Processor.Name)
$($Inventory.Processor.Cores) cores / $($Inventory.Processor.LogicalProcessors) logical
Current $($Inventory.Processor.CurrentClockMHz) MHz | Load $($Inventory.Processor.LoadPercent)%

Memory:
$($Inventory.Computer.TotalRAMGB) GB installed
$($Inventory.OperatingSystem.FreeRAMGB) GB currently free

Graphics:
$gpuText

Storage:
$diskText

Thermal:
$temperatureText
"@
}

function Export-NoxoraReport {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $reportFolder = Join-Path $desktop "NoxoraReports"

    if (-not (Test-Path -LiteralPath $reportFolder)) {
        New-Item -ItemType Directory -Path $reportFolder -Force | Out-Null
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $jsonPath = Join-Path $reportFolder "Noxora-Report-$stamp.json"
    $textPath = Join-Path $reportFolder "Noxora-Report-$stamp.txt"

    $script:LastReport.GeneratedAt = (Get-Date).ToString("o")
    $script:LastReport |
        ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $jsonPath -Encoding UTF8

    $textLines = New-Object System.Collections.Generic.List[string]
    $textLines.Add("NOXORA OPTIMIZER REPORT")
    $textLines.Add(("Generated: {0}" -f (Get-Date)))
    $textLines.Add(("Computer: {0}" -f $env:COMPUTERNAME))
    $textLines.Add(("Windows user: {0}" -f [Environment]::UserName))
    $textLines.Add("")
    $textLines.Add(($script:LastReport | ConvertTo-Json -Depth 8))
    $textLines | Set-Content -LiteralPath $textPath -Encoding UTF8

    [pscustomobject]@{
        Folder   = $reportFolder
        JsonFile = $jsonPath
        TextFile = $textPath
    }
}

# ------------------------------------------------------------------------------
# Main dashboard
# ------------------------------------------------------------------------------
$xamlMain = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Noxora Optimizer"
        Height="760"
        Width="1080"
        MinHeight="680"
        MinWidth="960"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style x:Key="NoxoraCardButton" TargetType="Button">
            <Setter Property="Background" Value="#1e1e2e"/>
            <Setter Property="Foreground" Value="#cdd6f4"/>
            <Setter Property="BorderBrush" Value="#45475a"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="7"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="10"/>
        </Style>
    </Window.Resources>

    <Border Background="#11111b"
            CornerRadius="16"
            BorderBrush="#f38ba8"
            BorderThickness="1.5"
            Margin="14">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="56"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="220"/>
                <RowDefinition Height="28"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0" Name="DragArea" Background="#181825">
                <TextBlock Text="NOXORA SYSTEM OPTIMIZER 2.0 SAFE"
                           Foreground="#f38ba8"
                           VerticalAlignment="Center"
                           Margin="24,0,0,0"
                           FontWeight="Black"
                           FontSize="15"/>
                <StackPanel Orientation="Horizontal"
                            HorizontalAlignment="Right">
                    <Button Name="BtnMinimize"
                            Content="_"
                            Width="44"
                            Background="Transparent"
                            Foreground="#a6adc8"
                            BorderThickness="0"
                            FontSize="16"
                            Cursor="Hand"/>
                    <Button Name="BtnClose"
                            Content="X"
                            Width="44"
                            Background="Transparent"
                            Foreground="#f38ba8"
                            BorderThickness="0"
                            FontSize="15"
                            FontWeight="Bold"
                            Cursor="Hand"/>
                </StackPanel>
            </Grid>

            <Grid Grid.Row="1" Margin="16,14,16,12">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="335"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Border Grid.Column="0"
                        Background="#181825"
                        BorderBrush="#313244"
                        BorderThickness="1"
                        CornerRadius="10"
                        Margin="0,0,12,0">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="42"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <TextBlock Grid.Row="0"
                                   Text="LIVE SYSTEM SUMMARY"
                                   Foreground="#89b4fa"
                                   FontWeight="Black"
                                   FontSize="12"
                                   Margin="16,14,0,0"/>
                        <TextBox Name="TxtSummary"
                                 Grid.Row="1"
                                 IsReadOnly="True"
                                 Background="Transparent"
                                 Foreground="#cdd6f4"
                                 BorderThickness="0"
                                 TextWrapping="Wrap"
                                 VerticalScrollBarVisibility="Auto"
                                 FontFamily="Consolas"
                                 FontSize="12"
                                 Padding="15,4,15,15"
                                 Text="Select SYSTEM SCAN to collect machine information."/>
                    </Grid>
                </Border>

                <UniformGrid Grid.Column="1" Columns="3" Rows="4">
                    <Button Name="BtnScan"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="SYSTEM SCAN"/>
                    <Button Name="BtnHardware"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="HARDWARE INVENTORY"/>
                    <Button Name="BtnProcesses"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="PROCESS AUDIT"/>

                    <Button Name="BtnStartup"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="STARTUP AUDIT"/>
                    <Button Name="BtnServices"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="SERVICE AUDIT"/>
                    <Button Name="BtnNetwork"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="NETWORK DIAGNOSTICS"/>

                    <Button Name="BtnSecurity"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="SECURITY STATUS"/>
                    <Button Name="BtnOptimize"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="SAFE OPTIMIZE"/>
                    <Button Name="BtnGameMode"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="REVERSIBLE GAME PROFILE"/>

                    <Button Name="BtnRollback"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="ROLLBACK LAST TUNE"/>
                    <Button Name="BtnExport"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="EXPORT REPORT"/>
                    <Button Name="BtnOpenLogs"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="OPEN LOG FOLDER"/>
                </UniformGrid>
            </Grid>

            <Border Grid.Row="2"
                    Background="#1e1e2e"
                    BorderBrush="#313244"
                    BorderThickness="0,2,0,0">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="38"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <TextBlock Grid.Row="0"
                               Text="AUDIT CONSOLE"
                               Foreground="#a6e3a1"
                               FontWeight="Black"
                               FontSize="12"
                               Margin="18,13,0,0"/>
                    <TextBox Name="TxtConsole"
                             Grid.Row="1"
                             IsReadOnly="True"
                             Background="Transparent"
                             Foreground="#89b4fa"
                             BorderThickness="0"
                             Margin="14,0,14,12"
                             TextWrapping="Wrap"
                             VerticalScrollBarVisibility="Auto"
                             FontFamily="Consolas"
                             FontSize="12"
                             Text="[SYSTEM] Authentication complete. Safe administration mode active.&#x0a;"/>
                </Grid>
            </Border>

            <Grid Grid.Row="3" Background="#181825">
                <TextBlock Text="No automatic process killing | No security bypass | No remote payloads"
                           Foreground="#6c7086"
                           FontSize="10"
                           VerticalAlignment="Center"
                           Margin="16,0,0,0"/>
                <TextBlock Text="LOCAL ADMIN SESSION"
                           Foreground="#a6adc8"
                           FontSize="10"
                           VerticalAlignment="Center"
                           HorizontalAlignment="Right"
                           Margin="0,0,16,0"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

$readerMain = New-Object System.Xml.XmlNodeReader ([xml]$xamlMain)
$script:windowMain = [Windows.Markup.XamlReader]::Load($readerMain)

$dragArea     = $script:windowMain.FindName("DragArea")
$btnMinimize  = $script:windowMain.FindName("BtnMinimize")
$btnClose     = $script:windowMain.FindName("BtnClose")
$script:txtConsole = $script:windowMain.FindName("TxtConsole")
$script:txtSummary = $script:windowMain.FindName("TxtSummary")

$btnScan      = $script:windowMain.FindName("BtnScan")
$btnHardware  = $script:windowMain.FindName("BtnHardware")
$btnProcesses = $script:windowMain.FindName("BtnProcesses")
$btnStartup   = $script:windowMain.FindName("BtnStartup")
$btnServices  = $script:windowMain.FindName("BtnServices")
$btnNetwork   = $script:windowMain.FindName("BtnNetwork")
$btnSecurity  = $script:windowMain.FindName("BtnSecurity")
$btnOptimize  = $script:windowMain.FindName("BtnOptimize")
$btnGameMode  = $script:windowMain.FindName("BtnGameMode")
$btnRollback  = $script:windowMain.FindName("BtnRollback")
$btnExport    = $script:windowMain.FindName("BtnExport")
$btnOpenLogs  = $script:windowMain.FindName("BtnOpenLogs")

$dragArea.Add_MouseLeftButtonDown({
    if ($_.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) {
        $script:windowMain.DragMove()
    }
})

$btnMinimize.Add_Click({
    $script:windowMain.WindowState = [System.Windows.WindowState]::Minimized
})

$btnClose.Add_Click({
    $script:windowMain.Close()
})

$btnHardware.Add_Click({
    Invoke-NoxoraAction -Title "Collecting hardware inventory" -Action {
        $inventory = Get-NoxoraSystemInventory
        $script:LastReport.Hardware = $inventory
        return $inventory
    } -OnSuccess {
        param($result)
        Set-NoxoraSummary (Format-NoxoraInventory $result)
    }
})

$btnProcesses.Add_Click({
    Invoke-NoxoraAction -Title "Auditing active processes" -Action {
        $result = Get-NoxoraProcessAudit
        $script:LastReport.ProcessAudit = $result
        return $result
    } -OnSuccess {
        param($result)

        $display = $result |
            Select-Object -First 15 PID, Name, CPU, RAMMB, Threads, Signature |
            Format-Table -AutoSize |
            Out-String -Width 120

        Set-NoxoraSummary (
            "TOP ACTIVE PROCESSES`r`n`r`n" +
            $display +
            "`r`nNoxora only reports suspicious indicators. It does not kill processes automatically."
        )
    }
})

$btnStartup.Add_Click({
    Invoke-NoxoraAction -Title "Auditing startup locations" -Action {
        $result = Get-NoxoraStartupAudit
        $script:LastReport.StartupAudit = $result
        return $result
    } -OnSuccess {
        param($result)

        $registryText = $result.RegistryEntries |
            Select-Object Scope, Name, Command |
            Format-Table -Wrap |
            Out-String -Width 120

        Set-NoxoraSummary @"
STARTUP AUDIT

Registry entries: $($result.RegistryEntries.Count)
Startup folder files: $($result.StartupFiles.Count)
Third-party scheduled tasks: $($result.ScheduledTasks.Count)

REGISTRY STARTUP
$registryText
"@
    }
})

$btnServices.Add_Click({
    Invoke-NoxoraAction -Title "Auditing Windows services" -Action {
        $result = Get-NoxoraServiceAudit
        $script:LastReport.ServiceAudit = $result
        return $result
    } -OnSuccess {
        param($result)

        $stoppedText = $result.AutomaticButStopped |
            Select-Object -First 20 Name, DisplayName, StartName |
            Format-Table -Wrap |
            Out-String -Width 120

        Set-NoxoraSummary @"
SERVICE AUDIT

Total services: $($result.TotalServices)
Running services: $($result.RunningServices)
Automatic but stopped: $($result.AutomaticButStopped.Count)
Third-party automatic services: $($result.ThirdPartyAutomatic.Count)

AUTOMATIC BUT STOPPED
$stoppedText

Review before changing any service. Noxora does not disable services automatically.
"@
    }
})

$btnNetwork.Add_Click({
    Invoke-NoxoraAction -Title "Running network diagnostics" -Action {
        $result = Get-NoxoraNetworkAudit
        $script:LastReport.NetworkAudit = $result
        return $result
    } -OnSuccess {
        param($result)

        $adapterText = $result.Adapters |
            Format-Table Name, Status, LinkSpeed, MacAddress -AutoSize |
            Out-String -Width 120

        Set-NoxoraSummary @"
NETWORK DIAGNOSTICS

Default gateway: $($result.DefaultGateway)
Gateway reachable: $($result.GatewayReachable)
DNS resolution: $($result.DnsResolution)
Established TCP connections: $($result.EstablishedConnections)

ADAPTERS
$adapterText
"@
    }
})

$btnSecurity.Add_Click({
    Invoke-NoxoraAction -Title "Checking Windows security status" -Action {
        $result = Get-NoxoraSecurityAudit
        $script:LastReport.SecurityAudit = $result
        return $result
    } -OnSuccess {
        param($result)

        $firewallText = $result.Firewall |
            Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction |
            Out-String -Width 120

        $defenderText = if ($null -ne $result.Defender) {
            $result.Defender | Format-List | Out-String
        } else {
            "Microsoft Defender status is unavailable."
        }

        Set-NoxoraSummary @"
SECURITY STATUS

UAC enabled: $($result.UACEnabled)
Secure Boot: $($result.SecureBoot)

FIREWALL
$firewallText

DEFENDER
$defenderText
"@
    }
})

$btnOptimize.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Safe Optimize will create a rollback snapshot, attempt a restore point, remove old temporary files, flush DNS, and select High Performance power mode. Continue?",
        "Noxora Safe Optimize",
        "YesNo",
        "Question"
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    Invoke-NoxoraAction -Title "Applying safe optimization profile" -Action {
        $result = Invoke-NoxoraSafeOptimize
        $script:LastReport.SafeOptimize = $result
        return $result
    } -OnSuccess {
        param($result)
        Set-NoxoraSummary ($result | Format-List | Out-String)
    }
})

$btnGameMode.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "The reversible game profile enables Windows Game Mode, disables Game DVR capture, and selects High Performance power mode. Continue?",
        "Noxora Game Profile",
        "YesNo",
        "Question"
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    Invoke-NoxoraAction -Title "Applying reversible game profile" -Action {
        $result = Invoke-NoxoraGameProfile
        $script:LastReport.GameProfile = $result
        return $result
    } -OnSuccess {
        param($result)
        Set-NoxoraSummary ($result | Format-List | Out-String)
    }
})

$btnRollback.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Restore the registry and power-plan values saved before the most recent tune?",
        "Noxora Rollback",
        "YesNo",
        "Question"
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    Invoke-NoxoraAction -Title "Restoring previous system state" -Action {
        $result = Restore-NoxoraSystemState
        $script:LastReport.Rollback = $result
        return $result
    } -OnSuccess {
        param($result)
        Set-NoxoraSummary ($result | Format-List | Out-String)
    }
})

$btnExport.Add_Click({
    Invoke-NoxoraAction -Title "Exporting local audit report" -Action {
        if (-not $script:LastReport.Contains("Hardware")) {
            $script:LastReport.Hardware = Get-NoxoraSystemInventory
        }
        return Export-NoxoraReport
    } -OnSuccess {
        param($result)
        Set-NoxoraSummary @"
REPORT EXPORTED

JSON:
$($result.JsonFile)

TEXT:
$($result.TextFile)
"@
        Start-Process -FilePath "explorer.exe" -ArgumentList "`"$($result.Folder)`""
    }
})

$btnOpenLogs.Add_Click({
    Start-Process -FilePath "explorer.exe" -ArgumentList "`"$script:LogRoot`""
})

$btnScan.Add_Click({
    Invoke-NoxoraAction -Title "Running combined system scan" -Action {
        $inventory = Get-NoxoraSystemInventory
        Invoke-NoxoraUiPump

        $processes = Get-NoxoraProcessAudit
        Invoke-NoxoraUiPump

        $network = Get-NoxoraNetworkAudit
        Invoke-NoxoraUiPump

        $security = Get-NoxoraSecurityAudit

        $script:LastReport.Hardware      = $inventory
        $script:LastReport.ProcessAudit  = $processes
        $script:LastReport.NetworkAudit  = $network
        $script:LastReport.SecurityAudit = $security

        [pscustomobject]@{
            Inventory = $inventory
            Processes = $processes
            Network   = $network
            Security  = $security
        }
    } -OnSuccess {
        param($result)

        Set-NoxoraSummary (
            (Format-NoxoraInventory $result.Inventory) +
            "`r`n`r`nQUICK HEALTH FLAGS`r`n" +
            "Gateway reachable: $($result.Network.GatewayReachable)`r`n" +
            "DNS resolution: $($result.Network.DnsResolution)`r`n" +
            "UAC enabled: $($result.Security.UACEnabled)`r`n" +
            "Firewall profiles checked: $($result.Security.Firewall.Count)`r`n" +
            "High-activity processes sampled: $($result.Processes.Count)"
        )
    }
})

$script:windowMain.Add_Closed({
    Write-NoxoraLog "Noxora session closed." "INFO"
    try {
        $script:Mutex.ReleaseMutex()
        $script:Mutex.Dispose()
    } catch {}
})

Write-NoxoraLog "Noxora dashboard initialized." "SUCCESS"
$script:windowMain.ShowDialog() | Out-Null