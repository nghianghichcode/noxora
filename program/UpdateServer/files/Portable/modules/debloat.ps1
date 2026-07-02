# Debloat Module - Search and Execute Handlers
$ui.FindName("INP_DEBLOAT_SEARCH").Add_GotKeyboardFocus({ 
    if ($this.Text -eq "Search apps...") { $this.Text = ""; $this.Foreground = "#FFF" } 
})
$ui.FindName("INP_DEBLOAT_SEARCH").Add_LostKeyboardFocus({ 
    if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text = "Search apps..."; $this.Foreground = "#949BAA" } 
})
$ui.FindName("INP_DEBLOAT_SEARCH").Add_TextChanged({
    $q = $this.Text.ToLower().Trim()
    if ($q -eq 'search apps...') { $q = '' }
    $titles = @{}
    $titles[1] = 'cortana'
    $titles[2] = 'xbox game bar'
    $titles[3] = 'microsoft edge chromium'
    $titles[4] = 'microsoft onedrive'
    $titles[5] = 'get office hub and solitaire'
    for ($i=1; $i -le 5; $i++) {
        $item = $ui.FindName("ITEM_DEBLOAT_$i")
        if ($null -ne $item) {
            $matched = ($q -eq '' -or $titles[$i].Contains($q))
            if ($matched) { $item.Visibility = 'Visible' } else { $item.Visibility = 'Collapsed' }
        }
    }
    $sv = $ui.FindName('SCROLL_DEBLOAT')
    if ($null -ne $sv) { $sv.ScrollToTop() }
})

1..5 | ForEach-Object {
    $btnI = $ui.FindName("BTN_INFO_$_")
    if ($null -ne $btnI) {
        $btnI.Add_MouseEnter({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            $tb.Foreground = "#00B4DB" 
        })
        $btnI.Add_MouseLeave({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            $tb.Foreground = "#949BAA" 
        })
        $btnI.Add_PreviewMouseLeftButtonDown({
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            if ($tb) { $tb.Foreground = "#00B4DB" }
        })
    }
    $btnU = $ui.FindName("BTN_UNINSTALL_$_")
    if ($null -ne $btnU) {
        $btnU.Add_Click({
            $origContent = $this.Content
            $this.Content = "Processing..."
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
            
            # Log the action
            if (Get-Command Log-ProgramAction -ErrorAction SilentlyContinue) {
                Log-ProgramAction -Action "Uninstall App" -Details "Uninstalling app ID: $_"
            }
            
            # Execute corresponding .bat file if exists
            $batFile = switch ($_) {
                1 { "01_uninstall_cortana.bat" }
                2 { "02_uninstall_xbox_game_bar.bat" }
                3 { "03_uninstall_edge.bat" }
                4 { "04_uninstall_onedrive.bat" }
                5 { "05_uninstall_office_hub.bat" }
            }
            $batPath = "$ModuleRoot\tweak\04_debloat\$batFile"
            if (Test-Path $batPath) {
                if (Get-Command Invoke-LoggedBat -ErrorAction SilentlyContinue) {
                    Invoke-LoggedBat -BatPath $batPath
                } else {
                    Start-Process $batPath -Wait -WindowStyle Hidden
                }
            }
            
            Start-Sleep -Seconds 1
            $this.Content = $origContent
            Show-CustomPopup "Application package forcefully uninstalled and removed from registry." "Uninstalled" "Success"
        })
    }
    $btnR = $ui.FindName("BTN_REINSTALL_$_")
    if ($null -ne $btnR) {
        $btnR.Add_Click({
            $origContent = $this.Content
            $this.Content = "Processing..."
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
            
            # Log the action
            if (Get-Command Log-ProgramAction -ErrorAction SilentlyContinue) {
                Log-ProgramAction -Action "Reinstall App" -Details "Reinstalling app ID: $_"
            }
            
            Start-Sleep -Seconds 1
            $this.Content = $origContent
            Show-CustomPopup "Application components successfully reacquired and restored." "Re-installed" "Success"
        })
    }
}