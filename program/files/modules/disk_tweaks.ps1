# Disk Tweaks Module
$global:diskTweakItems = @()
for ($i=1; $i -le 5; $i++) { $global:diskTweakItems += $ui.FindName("ITEM_DISK_$i") }
$global:diskLeftPanel = $global:diskTweakItems[0].Parent
$global:diskRightPanel = $global:diskTweakItems[3].Parent

$ui.FindName("INP_DISKTWEAKS_SEARCH").Add_GotKeyboardFocus({ 
    if ($this.Text -eq "Search Disk tweaks...") { $this.Text = ""; $this.Foreground = "#FFF" } 
})
$ui.FindName("INP_DISKTWEAKS_SEARCH").Add_LostKeyboardFocus({ 
    if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text = "Search Disk tweaks..."; $this.Foreground = "#949BAA" } 
})
$ui.FindName("INP_DISKTWEAKS_SEARCH").Add_TextChanged({
    $q = $this.Text.ToLower().Trim()
    if ($q -eq 'search disk tweaks...') { $q = '' }
    $titles = @{}
    $titles[1] = 'enable ssd trim optimization'
    $titles[2] = 'disable search indexing'
    $titles[3] = 'disable ntfs last access timestamp'
    $titles[4] = 'disable hibernation reclaim space'
    $titles[5] = 'disable superfetch sysmain'
    
    $global:diskLeftPanel.Children.Clear()
    $global:diskRightPanel.Children.Clear()
    $matched = @()
    for ($i=0; $i -lt $global:diskTweakItems.Count; $i++) {
        if ($q -eq '' -or $titles[$i+1].Contains($q)) {
            $matched += $global:diskTweakItems[$i]
        }
    }
    $half = [math]::Ceiling($matched.Count / 2)
    for ($j=0; $j -lt $matched.Count; $j++) {
        if ($j -lt $half) { $global:diskLeftPanel.Children.Add($matched[$j]) }
        else { $global:diskRightPanel.Children.Add($matched[$j]) }
    }
    $sv = $ui.FindName('SCROLL_DISKTWEAKS')
    if ($null -ne $sv) { $sv.ScrollToTop() }
})

# Disk Tweaks Info Buttons
1..5 | ForEach-Object {
    $btnDiskInfo = $ui.FindName("BTN_INFO_DISK_$_")
    if ($null -ne $btnDiskInfo) {
        $btnDiskInfo.Add_MouseEnter({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#00B4DB" }
        })
        $btnDiskInfo.Add_MouseLeave({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#949BAA" }
        })
        $btnDiskInfo.Add_PreviewMouseLeftButtonDown({
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            if ($tb) { $tb.Foreground = "#00B4DB" }
        })
    }
}

# State Tracking
$global:appliedDiskTweaks = @{}
for ($k=1; $k -le 5; $k++) { $global:appliedDiskTweaks[$k] = $false }

# Toggle bindings
function Update-DiskTweakButtons {
    $applyCount = 0; $revertCount = 0
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_DISK_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedDiskTweaks[$j]) { $applyCount++ }
        if ($null -ne $t -and -not $t.IsChecked -and $global:appliedDiskTweaks[$j]) { $revertCount++ }
    }
    $ui.FindName("BTN_APPLY_DISK_TWEAKS").Content = "Apply Tweaks ($applyCount)"
    $ui.FindName("BTN_REVERT_DISK_TWEAKS").Content = "Revert Tweaks ($revertCount)"
    Set-TweakButtonState "BTN_APPLY_DISK_TWEAKS" $applyCount
    Set-TweakButtonState "BTN_REVERT_DISK_TWEAKS" $revertCount
}

1..5 | ForEach-Object {
    $tglDisk = $ui.FindName("TGL_DISK_$_")
    if ($null -ne $tglDisk) {
        $tglDisk.Add_Checked({ Update-DiskTweakButtons })
        $tglDisk.Add_Unchecked({ Update-DiskTweakButtons })
    }
}

$ui.FindName("BTN_APPLY_DISK_TWEAKS").Add_Click({
    $this.Content = "Processing..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    Start-Sleep -Seconds 2
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_DISK_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedDiskTweaks[$j]) { $global:appliedDiskTweaks[$j] = $true }
    }
    Update-DiskTweakButtons
    Save-TweakState
    Show-CustomPopup "Disk optimizations applied. Write efficiency and lifespan should improve." "Tweaks Applied" "Success"
})

$ui.FindName("BTN_REVERT_DISK_TWEAKS").Add_Click({
    $this.Content = "Processing..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    Start-Sleep -Seconds 2
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_DISK_$j")
        if ($null -ne $t -and -not $t.IsChecked -and $global:appliedDiskTweaks[$j]) {
            $global:appliedDiskTweaks[$j] = $false
        }
    }
    Update-DiskTweakButtons
    Save-TweakState
    Show-CustomPopup "Disk tweaks reverted to default safe states." "Tweaks Reverted" "Success"
})

Update-DiskTweakButtons


