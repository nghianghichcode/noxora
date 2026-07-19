# ==============================================================================
# PLATINUM+ OPTIMIZER - STANDALONE INSTALLER
# ==============================================================================
[System.Diagnostics.Process]::GetCurrentProcess().PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# 1. Nhúng trực tiếp giao diện XAML vào biến (Không cần tải từ mạng)
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Platinum+ Setup" Height="350" Width="600"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen">
    <Border Background="#1e1e2e" CornerRadius="12" BorderBrush="#89b4fa" BorderThickness="2">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="40"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="80"/>
            </Grid.RowDefinitions>
            
            <!-- Title Bar (Dùng để kéo thả cửa sổ) -->
            <Grid Grid.Row="0" Name="DragArea" Background="Transparent">
                <TextBlock Text="PLATINUM+ OPTIMIZER SETUP" Foreground="#a6adc8" VerticalAlignment="Center" Margin="15,0,0,0" FontWeight="Bold" FontSize="12"/>
                <Button Name="BtnClose" Content="✕" Width="40" HorizontalAlignment="Right" Background="Transparent" Foreground="#f38ba8" BorderThickness="0" FontSize="16" Cursor="Hand"/>
            </Grid>

            <!-- Main Content -->
            <StackPanel Grid.Row="1" VerticalAlignment="Center" HorizontalAlignment="Center">
                <TextBlock Text="PLATINUM+" Foreground="#89b4fa" FontSize="52" FontWeight="Black" HorizontalAlignment="Center"/>
                <TextBlock Text="Advanced Windows Optimization Tool" Foreground="#cdd6f4" FontSize="14" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                <TextBlock Text="Free up resources, reduce latency, and boost FPS." Foreground="#6c7086" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
            </StackPanel>

            <!-- Footer & Progress -->
            <Grid Grid.Row="2" Margin="30,0,30,0">
                <Button Name="BtnInstall" Content="INSTALL NOW" Background="#89b4fa" Foreground="#11111b" FontWeight="Bold" FontSize="14" Height="40" Width="200" Cursor="Hand" BorderThickness="0">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="6"/>
                        </Style>
                    </Button.Resources>
                </Button>
                
                <StackPanel Name="PanelProgress" Visibility="Collapsed" VerticalAlignment="Center">
                    <TextBlock Name="TxtStatus" Text="Preparing system..." Foreground="#cdd6f4" Margin="0,0,0,8" FontWeight="SemiBold"/>
                    <ProgressBar Name="BarProgress" Height="8" Minimum="0" Maximum="100" Foreground="#a6e3a1" Background="#313244" BorderThickness="0"/>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

# 2. Khởi tạo Giao diện từ chuỗi XAML
$reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
$window = [Windows.Markup.XamlReader]::Load($reader)

# 3. Kết nối các biến với giao diện
$dragArea = $window.FindName("DragArea")
$btnClose = $window.FindName("BtnClose")
$btnInstall = $window.FindName("BtnInstall")
$panelProgress = $window.FindName("PanelProgress")
$barProgress = $window.FindName("BarProgress")
$txtStatus = $window.FindName("TxtStatus")

# 4. Thêm chức năng tương tác (Kéo thả, Tắt)
$dragArea.Add_MouseLeftButtonDown({ $window.DragMove() })
$btnClose.Add_Click({ $window.Close() })

# 5. Logic khi bấm nút Cài đặt
$btnInstall.Add_Click({
    # Ẩn nút cài đặt, hiện thanh tiến trình
    $btnInstall.Visibility = "Collapsed"
    $panelProgress.Visibility = "Visible"
    
    # Mô phỏng quá trình cài đặt (Sử dụng Timer để UI không bị đơ)
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(50)
    $global:progressValue = 0
    
    $timer.Add_Tick({
        $global:progressValue += 1.5
        $barProgress.Value = $global:progressValue
        
        # Cập nhật trạng thái text theo tiến trình
        if ($global:progressValue -lt 30) {
            $txtStatus.Text = "Creating directories..."
        } elseif ($global:progressValue -lt 60) {
            $txtStatus.Text = "Extracting core files..."
        } elseif ($global:progressValue -lt 90) {
            $txtStatus.Text = "Creating shortcuts..."
        } else {
            $txtStatus.Text = "Finishing setup..."
        }
        
        # Khi hoàn thành
        if ($global:progressValue -ge 100) {
            $timer.Stop()
            $txtStatus.Text = "Installation Successful!"
            $txtStatus.Foreground = "#a6e3a1" # Màu xanh lá
            
            [System.Windows.Forms.MessageBox]::Show("Platinum+ Optimizer has been successfully installed!", "Success", "OK", "Information")
            $window.Close()
            
            # TƯƠNG LAI: Chỗ này sẽ gọi lệnh mở file tối ưu hóa chính (interfaccia_grafica.ps1)
        }
    })
    $timer.Start()
})

# Hiển thị cửa sổ
$window.ShowDialog() | Out-Null