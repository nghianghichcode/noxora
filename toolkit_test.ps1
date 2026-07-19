# ==============================================================================
# PLATINUM+ OPTIMIZER - SECURE EDITION (LOGIN + DASHBOARD + SCANNER)
# ==============================================================================
[System.Diagnostics.Process]::GetCurrentProcess().PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Biến toàn cục kiểm tra trạng thái đăng nhập
$global:IsAuthenticated = $false

# ==============================================================================
# PHẦN 1: MÀN HÌNH ĐĂNG NHẬP (LOGIN SCREEN)
# ==============================================================================
$xamlLogin = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Platinum+ Login" Height="300" Width="400"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen" Topmost="True">
    <Border Background="#1e1e2e" CornerRadius="12" BorderBrush="#89b4fa" BorderThickness="2">
        <Grid Margin="20">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            
            <Button Name="BtnExit" Grid.Row="0" Content="✕" Width="30" HorizontalAlignment="Right" Background="Transparent" Foreground="#f38ba8" BorderThickness="0" FontSize="16" Cursor="Hand"/>
            <TextBlock Grid.Row="0" Text="🔒 RESTRICTED ACCESS" Foreground="#89b4fa" FontSize="16" FontWeight="Black" HorizontalAlignment="Center" Margin="0,10,0,20"/>
            
            <!-- Username -->
            <TextBlock Grid.Row="1" Text="USERNAME" Foreground="#a6adc8" FontSize="11" Margin="10,0,0,5" FontWeight="Bold"/>
            <TextBox Name="TxtUser" Grid.Row="2" Background="#11111b" Foreground="#cdd6f4" FontSize="14" Padding="10,8" Margin="10,0,10,15" BorderThickness="0">
                <TextBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></TextBox.Resources>
            </TextBox>

            <!-- Password (Dùng PasswordBox để ẩn ký tự) -->
            <TextBlock Grid.Row="3" Text="PASSWORD" Foreground="#a6adc8" FontSize="11" Margin="10,0,0,5" FontWeight="Bold"/>
            <PasswordBox Name="TxtPass" Grid.Row="4" Background="#11111b" Foreground="#cdd6f4" FontSize="14" Padding="10,8" Margin="10,0,10,20" BorderThickness="0">
                <PasswordBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></PasswordBox.Resources>
            </PasswordBox>
            
            <Button Name="BtnLogin" Grid.Row="5" Content="AUTHORIZE" Margin="10,10,10,0" Background="#89b4fa" Foreground="#11111b" FontWeight="Bold" Height="40" Cursor="Hand" BorderThickness="0">
                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
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
    # --- THAY ĐỔI TÀI KHOẢN VÀ MẬT KHẨU CỦA BẠN Ở DÒNG NÀY ---
    if ($txtUser.Text -eq "xoan" -and $txtPass.Password -eq "nghiaxoan") {
        $global:IsAuthenticated = $true
        $windowLogin.Close()
    } else {
        [System.Windows.Forms.MessageBox]::Show("Truy cập bị từ chối! Sai tài khoản hoặc mật khẩu.", "Security Alert", "OK", "Error")
    }
})

# Ép Login bằng phím Enter
$windowLogin.Add_KeyDown({
    param($sender, $e)
    if ($e.Key -eq 'Enter') { $btnLogin.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))) }
})

$windowLogin.ShowDialog() | Out-Null

# NẾU ĐĂNG NHẬP THẤT BẠI HOẶC TẮT NGANG -> THOÁT TOÀN BỘ CHƯƠNG TRÌNH
if (-not $global:IsAuthenticated) {
    exit
}

# ==============================================================================
# PHẦN 2: BẢNG ĐIỀU KHIỂN CHÍNH (Chỉ hiện ra khi đã đăng nhập)
# ==============================================================================
$xamlMain = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Platinum+ Toolkit" Height="500" Width="750"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen">
    
    <Border Background="#1e1e2e" CornerRadius="12" BorderBrush="#cba6f7" BorderThickness="1.5">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="40"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="150"/>
            </Grid.RowDefinitions>
            
            <Grid Grid.Row="0" Name="DragArea" Background="Transparent">
                <TextBlock Text="PLATINUM+ TOOLKIT DASHBOARD" Foreground="#cba6f7" VerticalAlignment="Center" Margin="20,0,0,0" FontWeight="Bold" FontSize="13"/>
                <Button Name="BtnClose" Content="✕" Width="40" HorizontalAlignment="Right" Background="Transparent" Foreground="#f38ba8" BorderThickness="0" FontSize="16" Cursor="Hand"/>
            </Grid>

            <UniformGrid Grid.Row="1" Columns="2" Rows="2" Margin="20,10,20,10">
                <Button Name="BtnBackup" Margin="10" Background="#313244" BorderThickness="0" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="CREATE BACKUP" Foreground="#a6e3a1" FontWeight="Black" FontSize="18" HorizontalAlignment="Center"/>
                        <TextBlock Text="Tạo điểm khôi phục an toàn" Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Button>

                <Button Name="BtnDebloat" Margin="10" Background="#313244" BorderThickness="0" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="SMART SCANNER" Foreground="#f9e2af" FontWeight="Black" FontSize="18" HorizontalAlignment="Center"/>
                        <TextBlock Text="Quét &amp; Diệt Process ngầm" Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Button>

                <Button Name="BtnHardware" Margin="10" Background="#313244" BorderThickness="0" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="HARDWARE TWEAK" Foreground="#89b4fa" FontWeight="Black" FontSize="18" HorizontalAlignment="Center"/>
                        <TextBlock Text="Bật max CPU &amp; I/O" Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Button>

                <Button Name="BtnNetwork" Margin="10" Background="#313244" BorderThickness="0" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="NETWORK &amp; PING" Foreground="#f38ba8" FontWeight="Black" FontSize="18" HorizontalAlignment="Center"/>
                        <TextBlock Text="Tối ưu hóa kết nối Game" Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Button>
            </UniformGrid>

            <Border Grid.Row="2" Background="#11111b" CornerRadius="0,0,10,10" BorderBrush="#45475a" BorderThickness="0,2,0,0">
                <TextBox Name="TxtConsole" IsReadOnly="True" Background="Transparent" Foreground="#a6adc8" 
                         BorderThickness="0" Margin="10" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" 
                         FontFamily="Consolas" FontSize="12" Text="[SYSTEM READY] Xác thực thành công. Chào mừng System Admin!&#x0a;"/>
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

$btnBackup.Add_Click({
    Write-Console "Đang thiết lập System Restore Point..."
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Platinum_Optimizer_Backup" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
        Write-Console "-> THÀNH CÔNG: Đã tạo điểm khôi phục an toàn!"
    } catch {
        Write-Console "-> LỖI: Vui lòng chạy tool bằng quyền Administrator."
    }
})

$btnDebloat.Add_Click({
    Write-Console "Đang phân tích hệ thống và mở Smart Scanner..."
    $xamlScanner = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Smart Scanner" Height="450" Width="600"
            WindowStyle="None" AllowsTransparency="True" Background="Transparent"
            WindowStartupLocation="CenterScreen" Topmost="True">
        <Border Background="#1e1e2e" CornerRadius="12" BorderBrush="#f38ba8" BorderThickness="2">
            <Grid Margin="20">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="⚠️ KẾT QUẢ QUÉT HỆ THỐNG" Foreground="#f38ba8" FontSize="18" FontWeight="Black" HorizontalAlignment="Center"/>
                <TextBlock Grid.Row="1" Text="Đã phát hiện các tiến trình ngốn RAM. Vui lòng chọn để tiêu diệt:" Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,15"/>
                <Border Grid.Row="2" Background="#11111b" CornerRadius="8" Padding="10">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel Name="ListContainer" Orientation="Vertical"/>
                    </ScrollViewer>
                </Border>
                <Grid Grid.Row="3" Margin="0,15,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button Name="BtnKill" Content="TIÊU DIỆT ĐÃ CHỌN" Margin="0,0,10,0" Background="#f38ba8" Foreground="#11111b" FontWeight="Bold" Height="40" Cursor="Hand" BorderThickness="0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                    <Button Name="BtnCancel" Grid.Column="1" Content="BỎ QUA" Margin="10,0,0,0" Background="#45475a" Foreground="#cdd6f4" FontWeight="Bold" Height="40" Cursor="Hand" BorderThickness="0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
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
        $txt.Text = "Hệ thống đang cực kỳ nhẹ nhàng!"
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
        Write-Console "-> Đã hủy thao tác dọn dẹp."
    })

    $windowScan.ShowDialog() | Out-Null
})

$btnHardware.Add_Click({
    Write-Console "Đang cấu hình giao tiếp Phần cứng..."
    $HagsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    if (-not (Test-Path $HagsPath)) { New-Item -Path $HagsPath -Force | Out-Null }
    Set-ItemProperty -Path $HagsPath -Name "HwSchMode" -Value 2 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -ErrorAction SilentlyContinue
    & bcdedit /deletevalue useplatformclock 2>$null | Out-Null
    & bcdedit /set disabledynamictick yes 2>$null | Out-Null
    Write-Console "-> HOÀN TẤT: Đã gỡ bỏ giới hạn phần cứng!"
})

$btnNetwork.Add_Click({
    Write-Console "Đang tối ưu hóa TCP/IP Stack giảm độ trễ Ping..."
    & ipconfig /flushdns | Out-Null
    $RegNet = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty -Path $RegNet -Name "NetworkThrottlingIndex" -Value 0xffffffff -ErrorAction SilentlyContinue
    Write-Console "-> HOÀN TẤT: Mạng đã sẵn sàng."
})

$windowMain.ShowDialog() | Out-Null