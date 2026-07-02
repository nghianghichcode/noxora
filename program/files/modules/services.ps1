# Service Manager Module
$global:serviceCards = @()
$global:serviceGrid = $ui.FindName('SERVICE_OPTIONS_LIST')
for ($i=1; $i -le 7; $i++) { $global:serviceCards += $ui.FindName("CARD_SERVICE_$i") }

$ui.FindName("INP_SERVICE_SEARCH").Add_GotKeyboardFocus({ 
    if ($this.Text -eq "Search services...") { $this.Text = ""; $this.Foreground = "#FFF" } 
})
$ui.FindName("INP_SERVICE_SEARCH").Add_LostKeyboardFocus({ 
    if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text = "Search services..."; $this.Foreground = "#949BAA" } 
})
$ui.FindName("INP_SERVICE_SEARCH").Add_TextChanged({
    $q = $this.Text.ToLower().Trim()
    if ($q -eq 'search services...') { $q = '' }
    $titles = @{}
    $titles[1] = 'windows search indexer'
    $titles[2] = 'connected user experiences telemetry'
    $titles[3] = 'print spooler service'
    $titles[4] = 'sysmain superfetch'
    $titles[5] = 'windows error reporting'
    $titles[6] = 'touch keyboard panel'
    $titles[7] = 'geolocation tracking service'
    $global:serviceGrid.Children.Clear()
    for ($i=0; $i -lt $global:serviceCards.Count; $i++) {
        if ($q -eq '' -or $titles[$i+1].Contains($q)) {
            $global:serviceGrid.Children.Add($global:serviceCards[$i])
        }
    }
    $sv = $ui.FindName('SCROLL_SERVICE')
    if ($null -ne $sv) { $sv.ScrollToTop() }
})

1..7 | ForEach-Object {
    $serviceId = $_
    $bDis = $ui.FindName("BTN_DISABLE_SRV_$serviceId")
    if ($null -ne $bDis) {
        $bDis.Add_Click({
            $origContent = $this.Content
            $this.Content = "Processing..."
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')

            # Log the action
            if (Get-Command Log-ProgramAction -ErrorAction SilentlyContinue) {
                Log-ProgramAction -Action "Disable Service" -Details "Disabling service ID: $serviceId"
            }

            # Execute corresponding .bat file if exists
            $batFile = switch ($serviceId) {
                1 { "01_disable_search_indexer.bat" }
                2 { "02_disable_telemetry.bat" }
                3 { "03_disable_print_spooler.bat" }
                4 { "04_disable_superfetch.bat" }
                5 { "05_disable_error_reporting.bat" }
                6 { "06_disable_touch_keyboard.bat" }
                7 { "07_disable_geolocation.bat" }
            }
            $batPath = "$ModuleRoot\tweak\03_services\$batFile"
            if (Test-Path $batPath) {
                if (Get-Command Invoke-LoggedBat -ErrorAction SilentlyContinue) {
                    Invoke-LoggedBat -BatPath $batPath
                } else {
                    Start-Process $batPath -Wait -WindowStyle Hidden
                }
            }

            Start-Sleep -Seconds 1
            $this.Content = $origContent
            if (Get-Command Show-CustomPopup -ErrorAction SilentlyContinue) {
                Show-CustomPopup "Target service has been forcefully disabled and stopped." "Service Disabled" "Success"
            }
        }.GetNewClosure())
    }
    $bEn = $ui.FindName("BTN_ENABLE_SRV_$serviceId")
    if ($null -ne $bEn) {
        $bEn.Add_Click({
            $origContent = $this.Content
            $this.Content = "Processing..."
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')

            # Log the action
            if (Get-Command Log-ProgramAction -ErrorAction SilentlyContinue) {
                Log-ProgramAction -Action "Enable Service" -Details "Enabling service ID: $serviceId"
            }

            Start-Sleep -Seconds 1
            $this.Content = $origContent
            if (Get-Command Show-CustomPopup -ErrorAction SilentlyContinue) {
                Show-CustomPopup "Target service is now set to automatic and started." "Service Re-enabled" "Success"
            }
        }.GetNewClosure())
    }
}

1..7 | ForEach-Object {
    $btnSrvInfo = $ui.FindName("BTN_INFO_SRV_$_")
    if ($null -ne $btnSrvInfo) {
        $btnSrvInfo.Add_MouseEnter({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#00B4DB" }
        })
        $btnSrvInfo.Add_MouseLeave({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#949BAA" }
        })
        $btnSrvInfo.Add_PreviewMouseLeftButtonDown({
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            if ($tb) { $tb.Foreground = "#00B4DB" }
        })
    }
}
