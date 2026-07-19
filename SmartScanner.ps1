# ==============================================================================
# MODULE: PLATINUM+ SMART SCANNER (CỬA SỔ QUÉT VÀ TIÊU DIỆT TIẾN TRÌNH)
# ==============================================================================
[System.Diagnostics.Process]::GetCurrentProcess().PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# 1. GIAO DIỆN XAML (CỬA SỔ SCAN)
$xamlScanner = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Platinum+ Smart Scanner" Height="450" Width="600"
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
            
            <!-- Tiêu đề -->
            <TextBlock Grid.Row="0" Text="⚠️ KẾT QUẢ QUÉT HỆ THỐNG" Foreground="#f38ba8" FontSize="18" FontWeight="Black" HorizontalAlignment="Center"/>
            <TextBlock Grid.Row="1" Text="Đã phát hiện các tiến trình ngốn tài nguyên bất thường. Vui lòng chọn để tiêu diệt:" 
                       Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,15"/>
            
            <!-- Danh sách Checkbox tự động -->
            <Border Grid.Row="2" Background="#11111b" CornerRadius="8" Padding="10">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <!-- Đây là nơi Code PowerShell sẽ tự động nhét các ô Checkbox vào -->
                    <StackPanel Name="ListContainer" Orientation="Vertical"/>
                </ScrollViewer>
            </Border>
            
            <!-- Nút Hành động -->
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

# 2. KHỞI TẠO UI
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xamlScanner)
$windowScan = [Windows.Markup.XamlReader]::Load($reader)

$listContainer = $windowScan.FindName("ListContainer")
$btnKill = $windowScan.FindName("BtnKill")
$btnCancel = $windowScan.FindName("BtnCancel")

# 3. THUẬT TOÁN QUÉT (Chạy ngay khi mở cửa sổ)
# Lọc ra các tiến trình ngốn > 100MB RAM, CHỪA LẠI các tiến trình sống còn của Windows & VS Code
$CoreProcesses = @("Memory Compression", "svchost", "MsMpEng", "csrss", "smss", "System", "explorer", "Code", "devenv")
$HeavyProcs = Get-Process | Where-Object { $_.WorkingSet -gt 100MB -and $_.ProcessName -notin $CoreProcesses }

if ($HeavyProcs) {
    foreach ($proc in $HeavyProcs) {
        $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
        
        # Tự động tạo một ô Checkbox XAML bằng Code C#/PowerShell
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = "$($proc.ProcessName).exe (PID: $($proc.Id)) - Đang ngốn: $ramMB MB"
        $cb.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#cdd6f4")
        $cb.FontSize = 13
        $cb.Margin = "5,5,5,8"
        $cb.IsChecked = $true  # Mặc định tick chọn sẵn
        $cb.Tag = $proc.Id     # LƯU PID VÀO ĐÂY ĐỂ LÁT NỮA "BẮN" ĐÚNG MỤC TIÊU
        
        # Nhét Checkbox vào Giao diện
        $listContainer.Children.Add($cb) | Out-Null
    }
} else {
    # Nếu máy sạch, in ra câu thông báo
    $txt = New-Object System.Windows.Controls.TextBlock
    $txt.Text = "Hệ thống của bạn đang rất tối ưu. Không có tiến trình rác!"
    $txt.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#a6e3a1")
    $txt.HorizontalAlignment = "Center"
    $listContainer.Children.Add($txt) | Out-Null
}

# 4. LOGIC XỬ LÝ KHI BẤM NÚT
$btnKill.Add_Click({
    # Duyệt qua toàn bộ Checkbox trong danh sách
    foreach ($child in $listContainer.Children) {
        if ($child.GetType().Name -eq "CheckBox" -and $child.IsChecked -eq $true) {
            $pidToKill = $child.Tag
            Write-Host "Đang tiêu diệt PID: $pidToKill"
            # Lệnh "hành quyết"
            Stop-Process -Id $pidToKill -Force -ErrorAction SilentlyContinue
        }
    }
    [System.Windows.Forms.MessageBox]::Show("Đã dọn dẹp thành công các tiến trình được chọn!", "Hoàn tất", "OK", "Information")
    $windowScan.Close()
})

$btnCancel.Add_Click({ $windowScan.Close() })

# Hiển thị
$windowScan.ShowDialog() | Out-Null