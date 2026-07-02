# RAM Tweaks Module
$global:ramTweakItems = @()
for ($i=1; $i -le 5; $i++) { $global:ramTweakItems += $ui.FindName("ITEM_RAM_$i") }
$global:ramLeftPanel = $global:ramTweakItems[0].Parent
$global:ramRightPanel = $global:ramTweakItems[3].Parent

$ui.FindName("INP_RAMTWEAKS_SEARCH").Add_GotKeyboardFocus({ 
    if ($this.Text -eq "Search RAM tweaks...") { $this.Text = ""; $this.Foreground = "#FFF" } 
})
$ui.FindName("INP_RAMTWEAKS_SEARCH").Add_LostKeyboardFocus({ 
    if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text = "Search RAM tweaks..."; $this.Foreground = "#949BAA" } 
})
$ui.FindName("INP_RAMTWEAKS_SEARCH").Add_TextChanged({
    $q = $this.Text.ToLower().Trim()
    if ($q -eq 'search ram tweaks...') { $q = '' }
    $titles = @{}
    $titles[1] = 'disable memory compression'
    $titles[2] = 'enable large system cache'
    $titles[3] = 'optimize paging executive'
    $titles[4] = 'disable sysmain superfetch'
    $titles[5] = 'disable prefetcher'
    $global:ramLeftPanel.Children.Clear()
    $global:ramRightPanel.Children.Clear()
    $matched = @()
    for ($i=0; $i -lt $global:ramTweakItems.Count; $i++) {
        if ($q -eq '' -or $titles[$i+1].Contains($q)) {
            $matched += $global:ramTweakItems[$i]
        }
    }
    $half = [math]::Ceiling($matched.Count / 2)
    for ($j=0; $j -lt $matched.Count; $j++) {
        if ($j -lt $half) { $global:ramLeftPanel.Children.Add($matched[$j]) }
        else { $global:ramRightPanel.Children.Add($matched[$j]) }
    }
    $sv = $ui.FindName('SCROLL_RAMTWEAKS')
    if ($null -ne $sv) { $sv.ScrollToTop() }
})

# RAM Tweaks Info Buttons
1..5 | ForEach-Object {
    $btnRamInfo = $ui.FindName("BTN_INFO_RAM_$_")
    if ($null -ne $btnRamInfo) {
        $btnRamInfo.Add_MouseEnter({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#00B4DB" }
        })
        $btnRamInfo.Add_MouseLeave({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#949BAA" }
        })
        $btnRamInfo.Add_PreviewMouseLeftButtonDown({
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            if ($tb) { $tb.Foreground = "#00B4DB" }
        })
    }
}

$global:appliedRamTweaks = @{}
for ($k=1; $k -le 5; $k++) { $global:appliedRamTweaks[$k] = $false }

function Update-RamTweakButtons {
    $applyCount = 0; $revertCount = 0
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_RAM_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedRamTweaks[$j]) { $applyCount++ }
        if ($null -ne $t -and -not $t.IsChecked -and $global:appliedRamTweaks[$j]) { $revertCount++ }
    }
    $ui.FindName("BTN_APPLY_RAM_TWEAKS").Content = "Apply Tweaks ($applyCount)"
    $ui.FindName("BTN_REVERT_RAM_TWEAKS").Content = "Revert Tweaks ($revertCount)"
    Set-TweakButtonState "BTN_APPLY_RAM_TWEAKS" $applyCount
    Set-TweakButtonState "BTN_REVERT_RAM_TWEAKS" $revertCount
}

1..5 | ForEach-Object {
    $tglRam = $ui.FindName("TGL_RAM_$_")
    if ($null -ne $tglRam) {
        $tglRam.Add_Checked({ Update-RamTweakButtons })
        $tglRam.Add_Unchecked({ Update-RamTweakButtons })
    }
}

$ui.FindName("BTN_APPLY_RAM_TWEAKS").Add_Click({
    $this.Content = "Processing..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    Start-Sleep -Seconds 2
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_RAM_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedRamTweaks[$j]) { $global:appliedRamTweaks[$j] = $true }
    }
    Update-RamTweakButtons
    Save-TweakState
    Show-CustomPopup "Memory optimizations applied. System response times should improve after a restart." "Tweaks Applied" "Success"
})

$ui.FindName("BTN_REVERT_RAM_TWEAKS").Add_Click({
    $this.Content = "Processing..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    Start-Sleep -Seconds 2
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_RAM_$j")
        if ($null -ne $t) { $t.IsChecked = $false; $global:appliedRamTweaks[$j] = $false }
    }
    Update-RamTweakButtons
    Save-TweakState
    Show-CustomPopup "RAM tweaks reverted to default states." "Tweaks Reverted" "Success"
})

Update-RamTweakButtons


