#requires -Version 5.1
# ==============================================================================
# NOXORA OPTIMIZER - PHIÊN BẢN QUẢN TRỊ HỆ THỐNG AN TOÀN
# Mục đích: kiểm tra, chẩn đoán, tối ưu có thể hoàn tác và xuất báo cáo cục bộ.
# Tập lệnh này KHÔNG tải mã thực thi từ xa, tạo cơ chế bám trụ, ẩn tiến trình,
# tắt công cụ bảo mật, gửi dữ liệu ra ngoài, đào tiền mã hóa hoặc thực hiện botnet.
# ==============================================================================

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

try {
    [System.Diagnostics.Process]::GetCurrentProcess().PriorityClass =
        [System.Diagnostics.ProcessPriorityClass]::AboveNormal
} catch {}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# ------------------------------------------------------------------------------
# Đường dẫn ứng dụng và trạng thái toàn cục
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
    Version     = "2.1-safe"
    GeneratedAt = (Get-Date).ToString("o")
}

foreach ($folder in @($script:AppRoot, $script:LogRoot, $script:StateRoot)) {
    if (-not (Test-Path -LiteralPath $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}

# ------------------------------------------------------------------------------
# Kiểm tra an toàn và quyền quản trị
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
                "Noxora cần quyền Quản trị viên để hoạt động.",
                "Noxora Optimizer",
                "OK",
                "Warning"
            ) | Out-Null
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "Hãy mở PowerShell bằng quyền Quản trị viên, sau đó chạy lại Noxora.",
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
        "Noxora đang được chạy trong một cửa sổ khác.",
        "Noxora Optimizer",
        "OK",
        "Information"
    ) | Out-Null
    exit
}

# ------------------------------------------------------------------------------
# Hàm hỗ trợ nhật ký và giao diện
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

function ConvertTo-NoxoraYesNo {
    param($Value)

    if ($null -eq $Value) {
        return "Không xác định"
    }

    if ([bool]$Value) {
        return "Có"
    }

    return "Không"
}

function ConvertTo-NoxoraSignatureStatus {
    param([string]$Status)

    switch ($Status) {
        "Valid"         { return "Hợp lệ" }
        "NotSigned"     { return "Chưa ký số" }
        "HashMismatch"  { return "Sai mã băm" }
        "NotTrusted"    { return "Không tin cậy" }
        "UnknownError"  { return "Lỗi không xác định" }
        "CheckFailed"   { return "Kiểm tra thất bại" }
        "Unknown"       { return "Không xác định" }
        default           { return $Status }
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

        Write-NoxoraLog "$Title - hoàn tất." "SUCCESS"
    } catch {
        $message = $_.Exception.Message
        Write-NoxoraLog "$Title - thất bại: $message" "ERROR"
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
# Bảo vệ thông tin đăng nhập cục bộ bằng Windows DPAPI
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
        Write-NoxoraLog "Lỗi xác thực thông tin đăng nhập: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ------------------------------------------------------------------------------
# Thiết lập quản trị viên trong lần chạy đầu
# ------------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $script:CredentialFile)) {
    $xamlSetup = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Thiết lập Noxora lần đầu"
        Height="430" Width="520"
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
                       Text="THIẾT LẬP QUẢN TRỊ VIÊN LẦN ĐẦU"
                       Foreground="#89b4fa"
                       FontSize="17"
                       FontWeight="Black"
                       HorizontalAlignment="Center"
                       VerticalAlignment="Center"/>

            <TextBlock Grid.Row="1" Text="TÊN TÀI KHOẢN QUẢN TRỊ"
                       Foreground="#a6adc8" FontWeight="Bold" FontSize="11"/>
            <TextBox Name="SetupUser" Grid.Row="2"
                     Background="#11111b" Foreground="#cdd6f4"
                     BorderBrush="#45475a" Padding="12,9"
                     FontSize="14"/>

            <TextBlock Grid.Row="3" Text="MẬT KHẨU (TỐI THIỂU 10 KÝ TỰ)"
                       Foreground="#a6adc8" FontWeight="Bold" FontSize="11"
                       Margin="0,12,0,0"/>
            <PasswordBox Name="SetupPass" Grid.Row="4"
                         Background="#11111b" Foreground="#cdd6f4"
                         BorderBrush="#45475a" Padding="12,9"
                         FontSize="14"/>

            <TextBlock Grid.Row="5" Text="XÁC NHẬN MẬT KHẨU"
                       Foreground="#a6adc8" FontWeight="Bold" FontSize="11"
                       Margin="0,12,0,0"/>
            <PasswordBox Name="SetupConfirm" Grid.Row="6"
                         Background="#11111b" Foreground="#cdd6f4"
                         BorderBrush="#45475a" Padding="12,9"
                         FontSize="14"/>

            <Button Name="SetupCreate" Grid.Row="7"
                    Content="TẠO TÀI KHOẢN QUẢN TRỊ"
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
                "Tên tài khoản không được để trống.",
                "Thiết lập Noxora",
                "OK",
                "Warning"
            ) | Out-Null
            return
        }

        if ($pass.Length -lt 10) {
            [System.Windows.Forms.MessageBox]::Show(
                "Mật khẩu phải có ít nhất 10 ký tự.",
                "Thiết lập Noxora",
                "OK",
                "Warning"
            ) | Out-Null
            return
        }

        if ($pass -cne $confirm) {
            [System.Windows.Forms.MessageBox]::Show(
                "Mật khẩu xác nhận không khớp.",
                "Thiết lập Noxora",
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
# Màn hình đăng nhập
# ------------------------------------------------------------------------------
$xamlLogin = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Truy cập bảo mật Noxora"
        Height="360" Width="500"
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
                <TextBlock Text="CỔNG TRUY CẬP BẢO MẬT NOXORA"
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
                       Text="TÀI KHOẢN QUẢN TRỊ"
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
                       Text="MẬT KHẨU ĐƯỢC BẢO VỆ BỞI DPAPI"
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
                    Content="KHỞI TẠO PHIÊN BẢO MẬT"
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
        Write-NoxoraLog "Đã xác thực quản trị viên cục bộ." "SUCCESS"
        $windowLogin.Close()
        return
    }

    $remaining = 5 - $script:LoginAttempts
    if ($remaining -le 0) {
        Write-NoxoraLog "Đã khóa đăng nhập sau 5 lần nhập sai." "WARN"
        [System.Windows.Forms.MessageBox]::Show(
            "Bạn đã nhập sai quá nhiều lần. Noxora sẽ đóng.",
            "Bảo mật Noxora",
            "OK",
            "Error"
        ) | Out-Null
        $windowLogin.Close()
        return
    }

    [System.Windows.Forms.MessageBox]::Show(
        "Thông tin đăng nhập không hợp lệ. Số lần thử còn lại: $remaining",
        "Bảo mật Noxora",
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
# Các hàm kiểm kê và kiểm tra hệ thống
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
# Sao lưu trạng thái hệ thống để hoàn tác
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
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [ValidateSet("String", "ExpandString", "Binary", "DWord", "MultiString", "QWord")]
        [string]$DefaultType = "DWord"
    )

    $exists = $false
    $value = $null
    $type = $DefaultType

    if (Test-Path -LiteralPath $Path) {
        try {
            $registryKey = Get-Item -LiteralPath $Path -ErrorAction Stop
            $value = Get-ItemPropertyValue -LiteralPath $Path -Name $Name -ErrorAction Stop
            $type = $registryKey.GetValueKind($Name).ToString()
            $exists = $true
        } catch {}
    }

    [pscustomobject]@{
        Path   = $Path
        Name   = $Name
        Exists = $exists
        Value  = $value
        Type   = $type
    }
}

function Get-NoxoraServiceState {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $service = Get-CimInstance Win32_Service -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq $Name } |
        Select-Object -First 1

    if ($null -eq $service) {
        return [pscustomobject]@{
            Name      = $Name
            Exists    = $false
            StartMode = $null
            State     = $null
        }
    }

    [pscustomobject]@{
        Name      = $service.Name
        Exists    = $true
        StartMode = $service.StartMode
        State     = $service.State
    }
}

function Save-NoxoraSystemState {
    param(
        [switch]$IncludeDeepState
    )

    $registryTargets = @(
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_Enabled"; Type = "DWord" },
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"; Name = "AppCaptureEnabled"; Type = "DWord" },
        @{ Path = "HKCU:\SOFTWARE\Microsoft\GameBar"; Name = "AutoGameModeEnabled"; Type = "DWord" },
        @{ Path = "HKCU:\SOFTWARE\Microsoft\GameBar"; Name = "AllowAutoGameMode"; Type = "DWord" }
    )

    $serviceTargets = @()

    if ($IncludeDeepState) {
        $registryTargets += @(
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"; Name = "GlobalUserDisabled"; Type = "DWord" },
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; Name = "VisualFXSetting"; Type = "DWord" },
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ListviewAlphaSelect"; Type = "DWord" },
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ListviewShadow"; Type = "DWord" },
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarAnimations"; Type = "DWord" },
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "IconsOnly"; Type = "DWord" },
            @{ Path = "HKCU:\Control Panel\Desktop"; Name = "FontSmoothing"; Type = "String" }
        )

        $serviceTargets = @(
            "DiagTrack",
            "MapsBroker",
            "Spooler",
            "WbioSrvc",
            "wisvc"
        )
    }

    $registryState = foreach ($target in $registryTargets) {
        Get-NoxoraRegistryState `
            -Path $target.Path `
            -Name $target.Name `
            -DefaultType $target.Type
    }

    $serviceState = foreach ($serviceName in $serviceTargets) {
        Get-NoxoraServiceState -Name $serviceName
    }

    $state = [pscustomobject]@{
        CreatedAt         = (Get-Date).ToString("o")
        ActivePowerScheme = Get-NoxoraActivePowerScheme
        Registry          = @($registryState)
        Services          = @($serviceState)
        IncludesDeepState = [bool]$IncludeDeepState
    }

    $timestampFile = Join-Path $script:StateRoot (
        "state-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss")
    )

    $json = $state | ConvertTo-Json -Depth 10
    $json | Set-Content -LiteralPath $timestampFile -Encoding UTF8
    $json | Set-Content -LiteralPath $script:LatestState -Encoding UTF8

    Write-NoxoraLog "Đã lưu trạng thái hoàn tác: $timestampFile" "SUCCESS"
    return $state
}

function New-NoxoraRestorePoint {
    try {
        Checkpoint-Computer `
            -Description ("Noxora Safe Tune {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm")) `
            -RestorePointType "MODIFY_SETTINGS" `
            -ErrorAction Stop
        Write-NoxoraLog "Đã tạo điểm khôi phục Windows." "SUCCESS"
        return $true
    } catch {
        Write-NoxoraLog (
            "Không thể tạo điểm khôi phục. System Protection có thể đang bị tắt: " +
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

function Set-NoxoraRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Value,

        [ValidateSet("String", "ExpandString", "Binary", "DWord", "MultiString", "QWord")]
        [string]$Type = "DWord"
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty `
        -LiteralPath $Path `
        -Name $Name `
        -Value $Value `
        -PropertyType $Type `
        -Force | Out-Null
}

function Set-NoxoraActivePowerScheme {
    param(
        [Parameter(Mandatory)]
        [string]$Scheme
    )

    $output = & powercfg.exe /setactive $Scheme 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ("Lệnh powercfg thất bại: " + (($output | Out-String).Trim()))
    }

    return $true
}

# ------------------------------------------------------------------------------
# Các cấu hình tối ưu an toàn
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
                "Xóa bộ nhớ đệm DNS thất bại: " + (($dnsOutput | Out-String).Trim())
            ) "WARN"
        }
    } catch {
        $dnsFlushed = $false
    }

    $powerChanged = $false
    try {
        $powerChanged = Set-NoxoraActivePowerScheme -Scheme "SCHEME_MIN"
    } catch {
        Write-NoxoraLog "Không thể sử dụng chế độ nguồn Hiệu năng cao: $($_.Exception.Message)" "WARN"
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

function Invoke-NoxoraDeepOptimize {
    Save-NoxoraSystemState -IncludeDeepState | Out-Null
    $restorePoint = New-NoxoraRestorePoint

    Write-NoxoraLog (
        "Đã chủ động bỏ qua thay đổi SvcHostSplitThresholdInKB để giữ ổn định " +
        "cho cơ chế tách dịch vụ của Windows."
    ) "INFO"

    $backgroundAppsDisabled = $false
    try {
        Set-NoxoraRegistryDword `
            -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
            -Name "GlobalUserDisabled" `
            -Value 1

        $backgroundAppsDisabled = $true
        Write-NoxoraLog "Đã vô hiệu hóa quyền chạy nền chung của ứng dụng người dùng." "SUCCESS"
    } catch {
        Write-NoxoraLog "Không thể thay đổi quyền chạy nền: $($_.Exception.Message)" "WARN"
    }

    $serviceNames = @(
        "DiagTrack",
        "MapsBroker",
        "Spooler",
        "WbioSrvc",
        "wisvc"
    )

    $serviceResults = foreach ($serviceName in $serviceNames) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

        if ($null -eq $service) {
            Write-NoxoraLog "Không tìm thấy dịch vụ $serviceName; đã bỏ qua." "INFO"
            [pscustomobject]@{
                Name          = $serviceName
                Found         = $false
                WasRunning    = $false
                Stopped       = $false
                Disabled      = $false
                Result        = "Không tồn tại trên máy"
            }
            continue
        }

        if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
            Write-NoxoraLog (
                "Dịch vụ $serviceName hiện không chạy; giữ nguyên kiểu khởi động " +
                "để tránh thay đổi không cần thiết."
            ) "INFO"

            [pscustomobject]@{
                Name          = $serviceName
                Found         = $true
                WasRunning    = $false
                Stopped       = $false
                Disabled      = $false
                Result        = "Đang dừng nên giữ nguyên"
            }
            continue
        }

        $stopped = $false
        $disabled = $false
        $resultMessage = "Không thay đổi"

        try {
            Stop-Service -Name $serviceName -ErrorAction Stop
            $stopped = $true

            Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
            $disabled = $true
            $resultMessage = "Đã dừng và vô hiệu hóa"

            Write-NoxoraLog "Đã dừng và vô hiệu hóa dịch vụ $serviceName." "SUCCESS"
        } catch {
            $resultMessage = "Thất bại: $($_.Exception.Message)"
            Write-NoxoraLog "Không thể tối ưu dịch vụ $($serviceName): $($_.Exception.Message)" "WARN"
        }

        [pscustomobject]@{
            Name          = $serviceName
            Found         = $true
            WasRunning    = $true
            Stopped       = $stopped
            Disabled      = $disabled
            Result        = $resultMessage
        }
    }

    $visualEffectsApplied = $false
    try {
        Set-NoxoraRegistryDword `
            -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
            -Name "VisualFXSetting" `
            -Value 3

        Set-NoxoraRegistryDword `
            -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "ListviewAlphaSelect" `
            -Value 0

        Set-NoxoraRegistryDword `
            -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "ListviewShadow" `
            -Value 0

        Set-NoxoraRegistryDword `
            -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "TaskbarAnimations" `
            -Value 0

        Set-NoxoraRegistryDword `
            -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "IconsOnly" `
            -Value 0

        Set-NoxoraRegistryValue `
            -Path "HKCU:\Control Panel\Desktop" `
            -Name "FontSmoothing" `
            -Value "2" `
            -Type "String"

        $visualEffectsApplied = $true
        Write-NoxoraLog (
            "Đã giảm hiệu ứng hình ảnh nhưng vẫn giữ thumbnail và làm mịn phông chữ."
        ) "SUCCESS"
    } catch {
        Write-NoxoraLog "Không thể áp dụng toàn bộ hiệu ứng hình ảnh: $($_.Exception.Message)" "WARN"
    }

    [pscustomobject]@{
        RestorePointCreated        = $restorePoint
        SvcHostThresholdWasSkipped = $true
        BackgroundAppsDisabled     = $backgroundAppsDisabled
        Services                   = @($serviceResults)
        VisualEffectsApplied       = $visualEffectsApplied
        ThumbnailsPreserved        = $true
        FontSmoothingPreserved     = $true
        StartupAppsRequireManualReview = $true
        SignOutRecommended         = $true
        RestartRequired            = $false
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
        Write-NoxoraLog "Không thể sử dụng chế độ nguồn Hiệu năng cao: $($_.Exception.Message)" "WARN"
    }

    [pscustomobject]@{
        RestorePointCreated = $restorePoint
        WindowsGameMode     = "Đã bật"
        GameDvrCapture      = "Đã tắt"
        PowerPlanChanged    = $powerChanged
        RestartRequired     = $false
    }
}

function Restore-NoxoraSystemState {
    if (-not (Test-Path -LiteralPath $script:LatestState)) {
        throw "Không tìm thấy trạng thái hoàn tác đã lưu."
    }

    $state = Get-Content -LiteralPath $script:LatestState -Raw | ConvertFrom-Json

    if ($state.PSObject.Properties.Name -contains "Registry") {
        foreach ($entry in $state.Registry) {
            if ($entry.Exists) {
                $entryType = "DWord"
                if (
                    $entry.PSObject.Properties.Name -contains "Type" -and
                    -not [string]::IsNullOrWhiteSpace([string]$entry.Type)
                ) {
                    $entryType = [string]$entry.Type
                }

                Set-NoxoraRegistryValue `
                    -Path ([string]$entry.Path) `
                    -Name ([string]$entry.Name) `
                    -Value $entry.Value `
                    -Type $entryType
            } else {
                if (Test-Path -LiteralPath ([string]$entry.Path)) {
                    Remove-ItemProperty `
                        -LiteralPath ([string]$entry.Path) `
                        -Name ([string]$entry.Name) `
                        -ErrorAction SilentlyContinue
                }
            }
        }
    }

    $serviceRestoreResults = @()
    if ($state.PSObject.Properties.Name -contains "Services") {
        $serviceRestoreResults = foreach ($entry in $state.Services) {
            if (-not $entry.Exists) {
                continue
            }

            $startupType = switch ([string]$entry.StartMode) {
                "Auto"     { "Automatic" }
                "Automatic"{ "Automatic" }
                "Manual"   { "Manual" }
                "Disabled" { "Disabled" }
                default    { "Manual" }
            }

            $startupRestored = $false
            $runningStateRestored = $false
            $message = "Đã khôi phục"

            try {
                Set-Service `
                    -Name ([string]$entry.Name) `
                    -StartupType $startupType `
                    -ErrorAction Stop
                $startupRestored = $true

                $currentService = Get-Service `
                    -Name ([string]$entry.Name) `
                    -ErrorAction Stop

                if ([string]$entry.State -eq "Running") {
                    if ($currentService.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
                        Start-Service -Name ([string]$entry.Name) -ErrorAction Stop
                    }
                    $runningStateRestored = $true
                } else {
                    if ($currentService.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) {
                        Stop-Service -Name ([string]$entry.Name) -ErrorAction Stop
                    }
                    $runningStateRestored = $true
                }

                Write-NoxoraLog "Đã khôi phục dịch vụ $($entry.Name)." "SUCCESS"
            } catch {
                $message = "Thất bại: $($_.Exception.Message)"
                Write-NoxoraLog "Hoàn tác dịch vụ $($entry.Name) thất bại: $($_.Exception.Message)" "WARN"
            }

            [pscustomobject]@{
                Name                 = [string]$entry.Name
                StartupTypeRestored  = $startupRestored
                RunningStateRestored = $runningStateRestored
                Result               = $message
            }
        }
    }

    $powerRestored = $false
    if ($state.ActivePowerScheme) {
        try {
            $powerRestored = Set-NoxoraActivePowerScheme `
                -Scheme ([string]$state.ActivePowerScheme)
        } catch {
            Write-NoxoraLog "Hoàn tác chế độ nguồn thất bại: $($_.Exception.Message)" "WARN"
        }
    }

    [pscustomobject]@{
        RestoredFrom       = $state.CreatedAt
        RegistryRestored   = $true
        ServicesRestored   = @($serviceRestoreResults)
        PowerPlanRestored  = $powerRestored
        SignOutRecommended = $true
        RestartRequired    = $false
    }
}

# ------------------------------------------------------------------------------
# Báo cáo và định dạng văn bản
# ------------------------------------------------------------------------------
function Format-NoxoraInventory {
    param($Inventory)

    $gpuText = if ($Inventory.Graphics.Count -gt 0) {
        ($Inventory.Graphics | ForEach-Object {
            "{0} | Trình điều khiển {1}" -f $_.Name, $_.DriverVersion
        }) -join "`r`n"
    } else {
        "Không phát hiện"
    }

    $diskText = if ($Inventory.LogicalDisks.Count -gt 0) {
        ($Inventory.LogicalDisks | ForEach-Object {
            "{0} còn trống {1} GB / {2} GB ({3}%)" -f
                $_.DeviceID, $_.FreeGB, $_.SizeGB, $_.FreePercent
        }) -join "`r`n"
    } else {
        "Không phát hiện"
    }

    $temperatureText = if ($Inventory.ThermalZoneCelsius.Count -gt 0) {
        ($Inventory.ThermalZoneCelsius -join ", ") + " °C"
    } else {
        "Firmware không cung cấp dữ liệu cảm biến"
    }

    return @"
TỔNG QUAN HỆ THỐNG

Máy tính:
$($Inventory.Computer.Manufacturer) $($Inventory.Computer.Model)

Hệ điều hành:
$($Inventory.OperatingSystem.Caption)
Bản dựng $($Inventory.OperatingSystem.BuildNumber) | $($Inventory.OperatingSystem.Architecture)

Bộ xử lý:
$($Inventory.Processor.Name)
$($Inventory.Processor.Cores) nhân / $($Inventory.Processor.LogicalProcessors) luồng xử lý
Xung hiện tại $($Inventory.Processor.CurrentClockMHz) MHz | Mức tải $($Inventory.Processor.LoadPercent)%

Bộ nhớ:
Đã lắp $($Inventory.Computer.TotalRAMGB) GB RAM
Hiện còn trống $($Inventory.OperatingSystem.FreeRAMGB) GB

Đồ họa:
$gpuText

Lưu trữ:
$diskText

Nhiệt độ:
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
    $textLines.Add("BÁO CÁO NOXORA OPTIMIZER")
    $textLines.Add(("Thời gian tạo: {0}" -f (Get-Date)))
    $textLines.Add(("Máy tính: {0}" -f $env:COMPUTERNAME))
    $textLines.Add(("Tài khoản Windows: {0}" -f [Environment]::UserName))
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
# Bảng điều khiển chính
# ------------------------------------------------------------------------------
$xamlMain = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Noxora Optimizer - Tối ưu hệ thống"
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
                <TextBlock Text="NOXORA - TỐI ƯU HỆ THỐNG 2.1 AN TOÀN"
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
                                   Text="TỔNG QUAN HỆ THỐNG"
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
                                 Text="Chọn QUÉT HỆ THỐNG để thu thập thông tin máy."/>
                    </Grid>
                </Border>

                <UniformGrid Grid.Column="1" Columns="3" Rows="5">
                    <Button Name="BtnScan"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="QUÉT HỆ THỐNG"/>
                    <Button Name="BtnHardware"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="THÔNG TIN PHẦN CỨNG"/>
                    <Button Name="BtnProcesses"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="KIỂM TRA TIẾN TRÌNH"/>

                    <Button Name="BtnStartup"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="KIỂM TRA KHỞI ĐỘNG"/>
                    <Button Name="BtnServices"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="KIỂM TRA DỊCH VỤ"/>
                    <Button Name="BtnNetwork"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="CHẨN ĐOÁN MẠNG"/>

                    <Button Name="BtnSecurity"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="TRẠNG THÁI BẢO MẬT"/>
                    <Button Name="BtnOptimize"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="TỐI ƯU AN TOÀN"/>
                    <Button Name="BtnDeepOptimize"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="TỐI ƯU CHUYÊN SÂU"/>
                    <Button Name="BtnGameMode"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="CẤU HÌNH CHƠI GAME"/>

                    <Button Name="BtnRollback"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="HOÀN TÁC TỐI ƯU"/>
                    <Button Name="BtnExport"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="XUẤT BÁO CÁO"/>
                    <Button Name="BtnOpenLogs"
                            Style="{StaticResource NoxoraCardButton}"
                            Content="MỞ THƯ MỤC NHẬT KÝ"/>
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
                               Text="BẢNG NHẬT KÝ KIỂM TRA"
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
                             Text="[HỆ THỐNG] Xác thực thành công. Chế độ quản trị an toàn đã sẵn sàng.&#x0a;"/>
                </Grid>
            </Border>

            <Grid Grid.Row="3" Background="#181825">
                <TextBlock Text="Không tự dừng tiến trình | Dịch vụ chỉ thay đổi sau xác nhận | Không chạy mã từ xa"
                           Foreground="#6c7086"
                           FontSize="10"
                           VerticalAlignment="Center"
                           Margin="16,0,0,0"/>
                <TextBlock Text="PHIÊN QUẢN TRỊ CỤC BỘ"
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
$btnDeepOptimize = $script:windowMain.FindName("BtnDeepOptimize")
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
    Invoke-NoxoraAction -Title "Đang thu thập thông tin phần cứng" -Action {
        $inventory = Get-NoxoraSystemInventory
        $script:LastReport.Hardware = $inventory
        return $inventory
    } -OnSuccess {
        param($result)
        Set-NoxoraSummary (Format-NoxoraInventory $result)
    }
})

$btnProcesses.Add_Click({
    Invoke-NoxoraAction -Title "Đang kiểm tra các tiến trình hoạt động" -Action {
        $result = Get-NoxoraProcessAudit
        $script:LastReport.ProcessAudit = $result
        return $result
    } -OnSuccess {
        param($result)

        $display = $result |
            Select-Object -First 15 `
                @{Name="PID"; Expression={$_.PID}}, `
                @{Name="Tiến trình"; Expression={$_.Name}}, `
                @{Name="CPU (%)"; Expression={$_.CPU}}, `
                @{Name="RAM (MB)"; Expression={$_.RAMMB}}, `
                @{Name="Luồng"; Expression={$_.Threads}}, `
                @{Name="Chữ ký số"; Expression={ConvertTo-NoxoraSignatureStatus $_.Signature}} |
            Format-Table -AutoSize |
            Out-String -Width 120

        Set-NoxoraSummary (
            "CÁC TIẾN TRÌNH HOẠT ĐỘNG CAO`r`n`r`n" +
            $display +
            "`r`nNoxora chỉ báo cáo các dấu hiệu cần chú ý và không tự động dừng tiến trình."
        )
    }
})

$btnStartup.Add_Click({
    Invoke-NoxoraAction -Title "Đang kiểm tra các vị trí tự khởi động" -Action {
        $result = Get-NoxoraStartupAudit
        $script:LastReport.StartupAudit = $result
        return $result
    } -OnSuccess {
        param($result)

        $registryText = $result.RegistryEntries |
            Select-Object `
                @{Name="Phạm vi"; Expression={
                    switch ($_.Scope) {
                        "CurrentUser"      { "Người dùng hiện tại" }
                        "CurrentUserOnce"  { "Người dùng hiện tại - một lần" }
                        "LocalMachine"     { "Toàn máy" }
                        "LocalMachineOnce" { "Toàn máy - một lần" }
                        "LocalMachine32"   { "Toàn máy - ứng dụng 32-bit" }
                        default             { $_.Scope }
                    }
                }}, `
                @{Name="Tên"; Expression={$_.Name}}, `
                @{Name="Lệnh"; Expression={$_.Command}} |
            Format-Table -Wrap |
            Out-String -Width 120

        Set-NoxoraSummary @"
KIỂM TRA KHỞI ĐỘNG

Mục Registry tự khởi động: $($result.RegistryEntries.Count)
Tệp trong thư mục Startup: $($result.StartupFiles.Count)
Tác vụ lập lịch bên thứ ba: $($result.ScheduledTasks.Count)

REGISTRY TỰ KHỞI ĐỘNG
$registryText
"@
    }
})

$btnServices.Add_Click({
    Invoke-NoxoraAction -Title "Đang kiểm tra dịch vụ Windows" -Action {
        $result = Get-NoxoraServiceAudit
        $script:LastReport.ServiceAudit = $result
        return $result
    } -OnSuccess {
        param($result)

        $stoppedText = $result.AutomaticButStopped |
            Select-Object -First 20 `
                @{Name="Tên dịch vụ"; Expression={$_.Name}}, `
                @{Name="Tên hiển thị"; Expression={$_.DisplayName}}, `
                @{Name="Tài khoản chạy"; Expression={$_.StartName}} |
            Format-Table -Wrap |
            Out-String -Width 120

        Set-NoxoraSummary @"
KIỂM TRA DỊCH VỤ

Tổng số dịch vụ: $($result.TotalServices)
Dịch vụ đang chạy: $($result.RunningServices)
Tự động nhưng đang dừng: $($result.AutomaticButStopped.Count)
Dịch vụ tự động của bên thứ ba: $($result.ThirdPartyAutomatic.Count)

DỊCH VỤ TỰ ĐỘNG NHƯNG ĐANG DỪNG
$stoppedText

Hãy kiểm tra kỹ trước khi thay đổi dịch vụ. Noxora không tự động tắt dịch vụ.
"@
    }
})

$btnNetwork.Add_Click({
    Invoke-NoxoraAction -Title "Đang chẩn đoán mạng" -Action {
        $result = Get-NoxoraNetworkAudit
        $script:LastReport.NetworkAudit = $result
        return $result
    } -OnSuccess {
        param($result)

        $adapterText = $result.Adapters |
            Select-Object `
                @{Name="Tên bộ điều hợp"; Expression={$_.Name}}, `
                @{Name="Trạng thái"; Expression={
                    switch ($_.Status) {
                        "Up"           { "Đang hoạt động" }
                        "Disconnected" { "Đã ngắt kết nối" }
                        "Disabled"     { "Đã tắt" }
                        default         { $_.Status }
                    }
                }}, `
                @{Name="Tốc độ liên kết"; Expression={$_.LinkSpeed}}, `
                @{Name="Địa chỉ MAC"; Expression={$_.MacAddress}} |
            Format-Table -AutoSize |
            Out-String -Width 120

        Set-NoxoraSummary @"
CHẨN ĐOÁN MẠNG

Cổng mạng mặc định: $($result.DefaultGateway)
Có thể kết nối tới cổng mạng: $(ConvertTo-NoxoraYesNo $result.GatewayReachable)
Phân giải DNS hoạt động: $(ConvertTo-NoxoraYesNo $result.DnsResolution)
Kết nối TCP đang thiết lập: $($result.EstablishedConnections)

BỘ ĐIỀU HỢP MẠNG
$adapterText
"@
    }
})

$btnSecurity.Add_Click({
    Invoke-NoxoraAction -Title "Đang kiểm tra trạng thái bảo mật Windows" -Action {
        $result = Get-NoxoraSecurityAudit
        $script:LastReport.SecurityAudit = $result
        return $result
    } -OnSuccess {
        param($result)

        $firewallText = $result.Firewall |
            Select-Object `
                @{Name="Hồ sơ"; Expression={$_.Name}}, `
                @{Name="Đang bật"; Expression={ConvertTo-NoxoraYesNo $_.Enabled}}, `
                @{Name="Luồng vào mặc định"; Expression={$_.DefaultInboundAction}}, `
                @{Name="Luồng ra mặc định"; Expression={$_.DefaultOutboundAction}} |
            Format-Table -AutoSize |
            Out-String -Width 120

        $defenderText = if ($null -ne $result.Defender) {
            if ($result.Defender.PSObject.Properties.Name -contains "Error") {
                "Không thể đọc trạng thái Microsoft Defender: $($result.Defender.Error)"
            }
            else {
@"
Chống virus: $(ConvertTo-NoxoraYesNo $result.Defender.AntivirusEnabled)
Chống phần mềm gián điệp: $(ConvertTo-NoxoraYesNo $result.Defender.AntispywareEnabled)
Bảo vệ thời gian thực: $(ConvertTo-NoxoraYesNo $result.Defender.RealTimeProtectionEnabled)
Giám sát hành vi: $(ConvertTo-NoxoraYesNo $result.Defender.BehaviorMonitorEnabled)
Bảo vệ tệp tải xuống: $(ConvertTo-NoxoraYesNo $result.Defender.IoavProtectionEnabled)
Bảo vệ mạng: $(ConvertTo-NoxoraYesNo $result.Defender.NISEnabled)
Lần quét nhanh gần nhất: $($result.Defender.LastQuickScan)
Tuổi cơ sở dữ liệu nhận diện: $($result.Defender.SignatureAgeDays) ngày
"@
            }
        } else {
            "Không thể đọc trạng thái Microsoft Defender."
        }

        Set-NoxoraSummary @"
TRẠNG THÁI BẢO MẬT

UAC đang bật: $(ConvertTo-NoxoraYesNo $result.UACEnabled)
Secure Boot đang bật: $(ConvertTo-NoxoraYesNo $result.SecureBoot)

TƯỜNG LỬA
$firewallText

MICROSOFT DEFENDER
$defenderText
"@
    }
})

$btnOptimize.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Tối ưu an toàn sẽ lưu trạng thái hoàn tác, thử tạo điểm khôi phục, xóa tệp tạm cũ, làm mới bộ nhớ đệm DNS và chọn chế độ nguồn Hiệu năng cao. Bạn có muốn tiếp tục không?",
        "Tối ưu an toàn Noxora",
        "YesNo",
        "Question"
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    Invoke-NoxoraAction -Title "Đang áp dụng cấu hình tối ưu an toàn" -Action {
        $result = Invoke-NoxoraSafeOptimize
        $script:LastReport.SafeOptimize = $result
        return $result
    } -OnSuccess {
        param($result)
        Set-NoxoraSummary @"
KẾT QUẢ TỐI ƯU AN TOÀN

Đã tạo điểm khôi phục: $(ConvertTo-NoxoraYesNo $result.RestorePointCreated)
Số tệp tạm đã xóa: $($result.TempFilesRemoved)
Dung lượng đã giải phóng: $($result.TempSpaceFreedMB) MB
Đã làm mới bộ nhớ đệm DNS: $(ConvertTo-NoxoraYesNo $result.DnsCacheFlushed)
Đã chọn chế độ nguồn Hiệu năng cao: $(ConvertTo-NoxoraYesNo $result.HighPerformancePlan)
Cần khởi động lại: $(ConvertTo-NoxoraYesNo $result.RestartRequired)
"@
    }
})


$btnDeepOptimize.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Tối ưu chuyên sâu sẽ vô hiệu hóa quyền chạy nền chung, dừng và vô hiệu hóa một số dịch vụ đang hoạt động, đồng thời giảm hiệu ứng hình ảnh.`r`n`r`nDịch vụ in (Spooler), sinh trắc học/vân tay (WbioSrvc), bản đồ ngoại tuyến (MapsBroker), chẩn đoán (DiagTrack) và Windows Insider (wisvc) có thể bị ảnh hưởng nếu đang chạy.`r`n`r`nCác ứng dụng khởi động cùng Windows không bị tự động tắt. Bạn cần tự quản lý chúng trong Task Manager > Startup Apps.`r`n`r`nBạn có muốn tiếp tục không?",
        "Tối ưu chuyên sâu Noxora",
        "YesNo",
        "Warning"
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    Invoke-NoxoraAction -Title "Đang áp dụng tối ưu chuyên sâu có thể hoàn tác" -Action {
        $result = Invoke-NoxoraDeepOptimize
        $script:LastReport.DeepOptimize = $result
        return $result
    } -OnSuccess {
        param($result)

        $serviceText = $result.Services |
            Select-Object `
                @{Name="Dịch vụ"; Expression={$_.Name}}, `
                @{Name="Kết quả"; Expression={$_.Result}} |
            Format-Table -AutoSize |
            Out-String -Width 120

        Set-NoxoraSummary @"
KẾT QUẢ TỐI ƯU CHUYÊN SÂU

Đã tạo điểm khôi phục: $(ConvertTo-NoxoraYesNo $result.RestorePointCreated)
Đã bỏ qua SvcHostSplitThresholdInKB: $(ConvertTo-NoxoraYesNo $result.SvcHostThresholdWasSkipped)
Đã tắt quyền chạy nền chung: $(ConvertTo-NoxoraYesNo $result.BackgroundAppsDisabled)
Đã áp dụng hiệu ứng hình ảnh nhẹ hơn: $(ConvertTo-NoxoraYesNo $result.VisualEffectsApplied)
Vẫn hiển thị thumbnail: $(ConvertTo-NoxoraYesNo $result.ThumbnailsPreserved)
Vẫn làm mịn phông chữ: $(ConvertTo-NoxoraYesNo $result.FontSmoothingPreserved)

DỊCH VỤ
$serviceText

Startup Apps: cần tự kiểm tra trong Task Manager
Khuyến nghị đăng xuất rồi đăng nhập lại: $(ConvertTo-NoxoraYesNo $result.SignOutRecommended)
Cần khởi động lại máy: $(ConvertTo-NoxoraYesNo $result.RestartRequired)
"@
    }
})

$btnGameMode.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Cấu hình chơi game có thể hoàn tác sẽ bật Windows Game Mode, tắt ghi hình Game DVR và chọn chế độ nguồn Hiệu năng cao. Bạn có muốn tiếp tục không?",
        "Cấu hình chơi game Noxora",
        "YesNo",
        "Question"
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    Invoke-NoxoraAction -Title "Đang áp dụng cấu hình chơi game có thể hoàn tác" -Action {
        $result = Invoke-NoxoraGameProfile
        $script:LastReport.GameProfile = $result
        return $result
    } -OnSuccess {
        param($result)
        Set-NoxoraSummary @"
KẾT QUẢ CẤU HÌNH CHƠI GAME

Đã tạo điểm khôi phục: $(ConvertTo-NoxoraYesNo $result.RestorePointCreated)
Windows Game Mode: $($result.WindowsGameMode)
Ghi hình Game DVR: $($result.GameDvrCapture)
Đã đổi chế độ nguồn: $(ConvertTo-NoxoraYesNo $result.PowerPlanChanged)
Cần khởi động lại: $(ConvertTo-NoxoraYesNo $result.RestartRequired)
"@
    }
})

$btnRollback.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Khôi phục Registry, dịch vụ và chế độ nguồn đã lưu trước lần tối ưu gần nhất?",
        "Hoàn tác Noxora",
        "YesNo",
        "Question"
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    Invoke-NoxoraAction -Title "Đang khôi phục trạng thái hệ thống trước đó" -Action {
        $result = Restore-NoxoraSystemState
        $script:LastReport.Rollback = $result
        return $result
    } -OnSuccess {
        param($result)
        Set-NoxoraSummary @"
KẾT QUẢ HOÀN TÁC

Khôi phục từ trạng thái lưu lúc: $($result.RestoredFrom)
Đã khôi phục Registry: $(ConvertTo-NoxoraYesNo $result.RegistryRestored)
Số dịch vụ đã xử lý hoàn tác: $($result.ServicesRestored.Count)
Đã khôi phục chế độ nguồn: $(ConvertTo-NoxoraYesNo $result.PowerPlanRestored)
Khuyến nghị đăng xuất rồi đăng nhập lại: $(ConvertTo-NoxoraYesNo $result.SignOutRecommended)
Cần khởi động lại: $(ConvertTo-NoxoraYesNo $result.RestartRequired)
"@
    }
})

$btnExport.Add_Click({
    Invoke-NoxoraAction -Title "Đang xuất báo cáo kiểm tra cục bộ" -Action {
        if (-not $script:LastReport.Contains("Hardware")) {
            $script:LastReport.Hardware = Get-NoxoraSystemInventory
        }
        return Export-NoxoraReport
    } -OnSuccess {
        param($result)
        Set-NoxoraSummary @"
ĐÃ XUẤT BÁO CÁO

Tệp JSON:
$($result.JsonFile)

Tệp văn bản:
$($result.TextFile)
"@
        Start-Process -FilePath "explorer.exe" -ArgumentList "`"$($result.Folder)`""
    }
})

$btnOpenLogs.Add_Click({
    Start-Process -FilePath "explorer.exe" -ArgumentList "`"$script:LogRoot`""
})

$btnScan.Add_Click({
    Invoke-NoxoraAction -Title "Đang quét tổng hợp hệ thống" -Action {
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
            "`r`n`r`nCHỈ BÁO SỨC KHỎE NHANH`r`n" +
            "Có thể kết nối tới cổng mạng: $(ConvertTo-NoxoraYesNo $result.Network.GatewayReachable)`r`n" +
            "Phân giải DNS hoạt động: $(ConvertTo-NoxoraYesNo $result.Network.DnsResolution)`r`n" +
            "UAC đang bật: $(ConvertTo-NoxoraYesNo $result.Security.UACEnabled)`r`n" +
            "Số hồ sơ tường lửa đã kiểm tra: $($result.Security.Firewall.Count)`r`n" +
            "Số tiến trình hoạt động cao đã lấy mẫu: $($result.Processes.Count)"
        )
    }
})

$script:windowMain.Add_Closed({
    Write-NoxoraLog "Đã đóng phiên làm việc Noxora." "INFO"
    try {
        $script:Mutex.ReleaseMutex()
        $script:Mutex.Dispose()
    } catch {}
})

Write-NoxoraLog "Bảng điều khiển Noxora đã sẵn sàng." "SUCCESS"
$script:windowMain.ShowDialog() | Out-Null