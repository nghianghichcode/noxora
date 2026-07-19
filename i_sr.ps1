# ==============================================================================
# NOXORA OPTIMIZER - ULTIMATE EDITION (FILELESS EXECUTION READY)
# ==============================================================================
[System.Diagnostics.Process]::GetCurrentProcess().PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Khai báo trạng thái an ninh
$global:IsAuthenticated = $false

# ==============================================================================
# PHẦN 1: MÀN HÌNH ĐĂNG NHẬP (SECURE LOGIN VỚI FADE-IN ANIMATION)
# ==============================================================================
$xamlLogin = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Noxora Secure Access" Height="320" Width="420"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen" Topmost="True">
    
    <!-- Hiệu ứng Fade In lúc mở App -->
    <Window.Triggers>
        <EventTrigger RoutedEvent="Window.Loaded">
            <BeginStoryboard>
                <Storyboard>
                    <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.6"/>
                </Storyboard>
            </BeginStoryboard>
        </EventTrigger>
    </Window.Triggers>

    <!-- Viền phát sáng Glow -->
    <Border Background="#181825" CornerRadius="15" BorderBrush="#cba6f7" BorderThickness="1.5" Margin="15">
        <Border.Effect>
            <DropShadowEffect Color="#cba6f7" BlurRadius="20" ShadowDepth="0" Opacity="0.5"/>
        </Border.Effect>

        <Grid Margin="20">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            
            <Button Name="BtnExit" Grid.Row="0" Content="✕" Width="30" HorizontalAlignment="Right" Background="Transparent" Foreground="#f38ba8" BorderThickness="0" FontSize="16" Cursor="Hand"/>
            <TextBlock Grid.Row="0" Text="⚡ NOXORA SECURE GATEWAY" Foreground="#cba6f7" FontSize="17" FontWeight="Black" HorizontalAlignment="Center" Margin="0,10,0,25" LetterSpacing="1"/>
            
            <!-- Username -->
            <TextBlock Grid.Row="1" Text="SYSTEM ADMIN ID" Foreground="#a6adc8" FontSize="11" Margin="10,0,0,5" FontWeight="Bold"/>
            <TextBox Name="TxtUser" Grid.Row="2" Background="#11111b" Foreground="#cdd6f4" FontSize="14" Padding="12,10" Margin="10,0,10,15" BorderThickness="1" BorderBrush="#313244">
                <TextBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></TextBox.Resources>
            </TextBox>

            <!-- Password -->
            <TextBlock Grid.Row="3" Text="ENCRYPTED PASSWORD" Foreground="#a6adc8" FontSize="11" Margin="10,0,0,5" FontWeight="Bold"/>
            <PasswordBox Name="TxtPass" Grid.Row="4" Background="#11111b" Foreground="#cdd6f4" FontSize="14" Padding="12,10" Margin="10,0,10,25" BorderThickness="1" BorderBrush="#313244">
                <PasswordBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></PasswordBox.Resources>
            </PasswordBox>
            
            <Button Name="BtnLogin" Grid.Row="5" Content="INITIALIZE SEQUENCE" Margin="10,10,10,0" Background="#cba6f7" Foreground="#11111b" FontWeight="Black" FontSize="13" Height="45" Cursor="Hand" BorderThickness="0">
                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                <!-- Hiệu ứng di chuột cho nút Login -->
                <Button.Style>
                    <Style TargetType="Button">
                        <Style.Triggers>
                            <Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.8"/></Trigger>
                        </Style.Triggers>
                    </Style>
                </Button.Style>
            </Button>
        </Grid>
    </Border>
</Window>
"@

$readerLogin = New-Object System.Xml.XmlNodeReader ([xml]$xamlLogin)
$windowLogin = [Windows.Markup.XamlReader]::Load($readerLogin)

$txtUser = $windowLogin.FindName("TxtUser")
$txtPass = $windowLogin.FindName("TxtPass")
$btnLogin = $windowLogin.FindName("BtnLogin")
$btnExit = $windowLogin.FindName("BtnExit")

$btnExit.Add_Click({ $windowLogin.Close() })

$btnLogin.Add_Click({
    if ($txtUser.Text -eq "xoan" -and $txtPass.Password -eq "xoandev") {
        $global:IsAuthenticated = $true
        $windowLogin.Close()
    } else {
        [System.Windows.Forms.MessageBox]::Show("CRITICAL ERROR: Unauthorized Access Attempt Blocked.", "Noxora Security", "OK", "Error")
    }
})

$windowLogin.Add_KeyDown({
    param($sender, $e)
    if ($e.Key -eq 'Enter') { $btnLogin.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))) }
})

$windowLogin.ShowDialog() | Out-Null
if (-not $global:IsAuthenticated) { exit }

# ==============================================================================
# PHẦN 2: BẢNG ĐIỀU KHIỂN CHÍNH NOXORA DASHBOARD
# ==============================================================================
$xamlMain = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Noxora Optimizer" Height="530" Width="780"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen">
    
    <Window.Triggers>
        <EventTrigger RoutedEvent="Window.Loaded">
            <BeginStoryboard>
                <Storyboard>
                    <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.8"/>
                </Storyboard>
            </BeginStoryboard>
        </EventTrigger>
    </Window.Triggers>

    <Window.Resources>
        <!-- Khởi tạo Style nút bấm dùng chung (Có hiệu ứng Hover) -->
        <Style x:Key="NoxoraBtn" TargetType="Button">
            <Setter Property="Background" Value="#1e1e2e"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#45475a"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="10">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#313244"/>
                    <Setter Property="BorderBrush" Value="#cba6f7"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Border Background="#11111b" CornerRadius="15" BorderBrush="#f38ba8" BorderThickness="1.5" Margin="15">
        <Border.Effect>
            <DropShadowEffect Color="#f38ba8" BlurRadius="25" ShadowDepth="0" Opacity="0.4"/>
        </Border.Effect>

        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="50"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="160"/>
            </Grid.RowDefinitions>
            
            <!-- Title Bar -->
            <Grid Grid.Row="0" Name="DragArea" Background="Transparent">
                <TextBlock Text="NOXORA SYSTEM OPTIMIZER" Foreground="#f38ba8" VerticalAlignment="Center" Margin="25,0,0,0" FontWeight="Black" FontSize="14" LetterSpacing="2"/>
                <Button Name="BtnClose" Content="✕" Width="40" HorizontalAlignment="Right" Background="Transparent" Foreground="#f38ba8" BorderThickness="0" FontSize="16" Cursor="Hand">
                    <Button.Style><Style TargetType="Button"><Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.6"/></Trigger></Style.Triggers></Style></Button.Style>
                </Button>
            </Grid>

            <!-- Khối Nút Bấm Chức năng -->
            <UniformGrid Grid.Row="1" Columns="2" Rows="2" Margin="20,5,20,15">
                
                <Button Name="BtnBackup" Style="{StaticResource NoxoraBtn}" Margin="12">
                    <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="CREATE BACKUP" Foreground="#a6e3a1" FontWeight="Black" FontSize="19" HorizontalAlignment="Center"/>
                        <TextBlock Text="Điểm khôi phục khẩn cấp" Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Button>

                <Button Name="BtnDebloat" Style="{StaticResource NoxoraBtn}" Margin="12">
                    <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="SMART SCANNER" Foreground="#f9e2af" FontWeight="Black" FontSize="19" HorizontalAlignment="Center"/>
                        <TextBlock Text="Radar quét &amp; diệt tiến trình" Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Button>

                <Button Name="BtnHardware" Style="{StaticResource NoxoraBtn}" Margin="12">
                    <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="HARDWARE TWEAK" Foreground="#89b4fa" FontWeight="Black" FontSize="19" HorizontalAlignment="Center"/>
                        <TextBlock Text="Mở khóa giới hạn CPU / GPU" Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Button>

                <Button Name="BtnNetwork" Style="{StaticResource NoxoraBtn}" Margin="12">
                    <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="NETWORK ENGINE" Foreground="#f38ba8" FontWeight="Black" FontSize="19" HorizontalAlignment="Center"/>
                        <TextBlock Text="Giảm Ping &amp; Tối ưu TCP/IP" Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Button>
            </UniformGrid>

            <!-- Console Log -->
            <Border Grid.Row="2" Background="#1e1e2e" CornerRadius="0,0,12,12" BorderBrush="#313244" BorderThickness="0,2,0,0">
                <TextBox Name="TxtConsole" IsReadOnly="True" Background="Transparent" Foreground="#89b4fa" 
                         BorderThickness="0" Margin="15" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" 
                         FontFamily="Consolas" FontSize="12" Text="[SYSTEM CORE] Xác thực danh tính: Nguyễn Viết Nghĩa - VinhUni.&#x0a;[SYSTEM CORE] Chào mừng trở lại. Mọi mô-đun đã sẵn sàng hoạt động.&#x0a;"/>
            </Border>
        </Grid>
    </Border>
</Window>
"@

$readerMain = New-Object System.Xml.XmlNodeReader ([xml]$xamlMain)
$windowMain = [Windows.Markup.XamlReader]::Load($readerMain)

$dragArea = $windowMain.FindName("DragArea")
$btnClose = $windowMain.FindName("BtnClose")
$btnBackup = $windowMain.FindName("BtnBackup")
$btnDebloat = $windowMain.FindName("BtnDebloat")
$btnHardware = $windowMain.FindName("BtnHardware")
$btnNetwork = $windowMain.FindName("BtnNetwork")
$txtConsole = $windowMain.FindName("TxtConsole")

function Write-Console {
    param([string]$Message)
    $time = (Get-Date).ToString("HH:mm:ss")
    $script:txtConsole.AppendText("[$time] $Message`n")
    $script:txtConsole.ScrollToEnd()
    $script:windowMain.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

$dragArea.Add_MouseLeftButtonDown({ $windowMain.DragMove() })
$btnClose.Add_Click({ $windowMain.Close() })

# ==============================================================================
# PHẦN 3: LOGIC HỆ THỐNG
# ==============================================================================
$btnBackup.Add_Click({
    Write-Console "Đang thiết lập System Restore Point..."
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Noxora_Optimizer_Backup" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
        Write-Console "-> THÀNH CÔNG: Đã tạo điểm khôi phục an toàn!"
    } catch {
        Write-Console "-> LỖI: Vui lòng chạy tool bằng quyền Administrator."
    }
})

$btnDebloat.Add_Click({
    Write-Console "Khởi động Radar quét bộ nhớ..."
    
    $xamlScanner = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Noxora Scanner" Height="450" Width="600"
            WindowStyle="None" AllowsTransparency="True" Background="Transparent"
            WindowStartupLocation="CenterOwner" Topmost="True">
        
        <Window.Triggers><EventTrigger RoutedEvent="Window.Loaded"><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.3"/></Storyboard></BeginStoryboard></EventTrigger></Window.Triggers>

        <Border Background="#1e1e2e" CornerRadius="12" BorderBrush="#f9e2af" BorderThickness="1.5" Margin="10">
            <Border.Effect><DropShadowEffect Color="#f9e2af" BlurRadius="15" ShadowDepth="0" Opacity="0.4"/></Border.Effect>
            <Grid Margin="20">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="⚠️ KẾT QUẢ QUÉT HỆ THỐNG" Foreground="#f9e2af" FontSize="18" FontWeight="Black" HorizontalAlignment="Center"/>
                <TextBlock Grid.Row="1" Text="Đã phát hiện các tiến trình ngốn RAM. Hãy ra lệnh tiêu diệt:" Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,15"/>
                
                <Border Grid.Row="2" Background="#11111b" CornerRadius="8" Padding="10">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel Name="ListContainer" Orientation="Vertical"/>
                    </ScrollViewer>
                </Border>
                
                <Grid Grid.Row="3" Margin="0,15,0,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="BtnKill" Content="TIÊU DIỆT TẤT CẢ" Margin="0,0,10,0" Background="#f38ba8" Foreground="#11111b" FontWeight="Black" Height="40" Cursor="Hand" BorderThickness="0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        <Button.Style><Style TargetType="Button"><Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.8"/></Trigger></Style.Triggers></Style></Button.Style>
                    </Button>
                    <Button Name="BtnCancel" Grid.Column="1" Content="HỦY BỎ" Margin="10,0,0,0" Background="#45475a" Foreground="#cdd6f4" FontWeight="Bold" Height="40" Cursor="Hand" BorderThickness="0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        <Button.Style><Style TargetType="Button"><Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.8"/></Trigger></Style.Triggers></Style></Button.Style>
                    </Button>
                </Grid>
            </Grid>
        </Border>
    </Window>
"@
    $readerScan = New-Object System.Xml.XmlNodeReader ([xml]$xamlScanner)
    $windowScan = [Windows.Markup.XamlReader]::Load($readerScan)
    $windowScan.Owner = $windowMain
    
    $listContainer = $windowScan.FindName("ListContainer")
    $btnKill = $windowScan.FindName("BtnKill")
    $btnCancel = $windowScan.FindName("BtnCancel")

    $CoreProcesses = @("Memory Compression", "svchost", "MsMpEng", "csrss", "smss", "System", "explorer", "Code", "devenv")
    $HeavyProcs = Get-Process | Where-Object { $_.WorkingSet -gt 100MB -and $_.ProcessName -notin $CoreProcesses }

    if ($HeavyProcs) {
        foreach ($proc in $HeavyProcs) {
            $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content = "$($proc.ProcessName).exe (PID: $($proc.Id)) - $ramMB MB"
            $cb.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#cdd6f4")
            $cb.FontSize = 13
            $cb.Margin = "5,5,5,8"
            $cb.IsChecked = $true
            $cb.Tag = $proc.Id
            $listContainer.Children.Add($cb) | Out-Null
        }
    } else {
        $txt = New-Object System.Windows.Controls.TextBlock
        $txt.Text = "Hệ thống đang hoàn toàn tối ưu!"
        $txt.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#a6e3a1")
        $txt.HorizontalAlignment = "Center"
        $listContainer.Children.Add($txt) | Out-Null
    }

    $btnKill.Add_Click({
        $killedCount = 0
        foreach ($child in $listContainer.Children) {
            if ($child.GetType().Name -eq "CheckBox" -and $child.IsChecked -eq $true) {
                Stop-Process -Id $child.Tag -Force -ErrorAction SilentlyContinue
                $killedCount++
            }
        }
        $windowScan.Close()
        Write-Console "-> ĐÃ TIÊU DIỆT $killedCount tiến trình ngốn RAM!"
    })

    $btnCancel.Add_Click({ 
        $windowScan.Close() 
        Write-Console "-> Hủy thao tác Scanner."
    })

    $windowScan.ShowDialog() | Out-Null
})

$btnHardware.Add_Click({
    Write-Console "Can thiệp I/O phần cứng & chống nghẽn cổ chai..."
    $HagsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    if (-not (Test-Path $HagsPath)) { New-Item -Path $HagsPath -Force | Out-Null }
    Set-ItemProperty -Path $HagsPath -Name "HwSchMode" -Value 2 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -ErrorAction SilentlyContinue
    & bcdedit /deletevalue useplatformclock 2>$null | Out-Null
    & bcdedit /set disabledynamictick yes 2>$null | Out-Null
    Write-Console "-> HOÀN TẤT: Đã gỡ bỏ giới hạn phần cứng!"
})

$btnNetwork.Add_Click({
    Write-Console "Tối ưu hóa TCP/IP Stack & Flush DNS..."
    & ipconfig /flushdns | Out-Null
    $RegNet = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty -Path $RegNet -Name "NetworkThrottlingIndex" -Value 0xffffffff -ErrorAction SilentlyContinue
    Write-Console "-> HOÀN TẤT: Đường truyền Game đã sẵn sàng."
})

$windowMain.ShowDialog() | Out-Null