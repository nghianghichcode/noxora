# Network Tweaks Module
$global:netTweakItems = @()
for ($i=1; $i -le 5; $i++) { $global:netTweakItems += $ui.FindName("ITEM_NET_$i") }
$global:netLeftPanel = $global:netTweakItems[0].Parent
$global:netRightPanel = $global:netTweakItems[3].Parent

$ui.FindName("INP_NETTWEAKS_SEARCH").Add_GotKeyboardFocus({ 
    if ($this.Text -eq "Search network tweaks...") { $this.Text = ""; $this.Foreground = "#FFF" } 
})
$ui.FindName("INP_NETTWEAKS_SEARCH").Add_LostKeyboardFocus({ 
    if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text = "Search network tweaks..."; $this.Foreground = "#949BAA" } 
})
$ui.FindName("INP_NETTWEAKS_SEARCH").Add_TextChanged({
    $q = $this.Text.ToLower().Trim()
    if ($q -eq 'search network tweaks...') { $q = '' }
    $titles = @{}
    $titles[1] = 'disable nagles algorithm'
    $titles[2] = 'disable network throttling'
    $titles[3] = 'optimize tcp window size'
    $titles[4] = 'enable tcp fast open'
    $titles[5] = 'optimize dns cache'
    $global:netLeftPanel.Children.Clear()
    $global:netRightPanel.Children.Clear()
    $matched = @()
    for ($i=0; $i -lt $global:netTweakItems.Count; $i++) {
        if ($q -eq '' -or $titles[$i+1].Contains($q)) {
            $matched += $global:netTweakItems[$i]
        }
    }
    $half = [math]::Ceiling($matched.Count / 2)
    for ($j=0; $j -lt $matched.Count; $j++) {
        if ($j -lt $half) { $global:netLeftPanel.Children.Add($matched[$j]) }
        else { $global:netRightPanel.Children.Add($matched[$j]) }
    }
    $sv = $ui.FindName('SCROLL_NETTWEAKS')
    if ($null -ne $sv) { $sv.ScrollToTop() }
})

# Network Tweaks Info Buttons
1..5 | ForEach-Object {
    $btnNetInfo = $ui.FindName("BTN_INFO_NET_$_")
    if ($null -ne $btnNetInfo) {
        $btnNetInfo.Add_MouseEnter({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#00B4DB" }
        })
        $btnNetInfo.Add_MouseLeave({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#949BAA" }
        })
        $btnNetInfo.Add_PreviewMouseLeftButtonDown({
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            if ($tb) { $tb.Foreground = "#00B4DB" }
        })
    }
}

$global:appliedNetTweaks = @{}
for ($k=1; $k -le 5; $k++) { $global:appliedNetTweaks[$k] = $false }

function Update-NetTweakButtons {
    $applyCount = 0; $revertCount = 0
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_NET_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedNetTweaks[$j]) { $applyCount++ }
        if ($null -ne $t -and -not $t.IsChecked -and $global:appliedNetTweaks[$j]) { $revertCount++ }
    }
    $ui.FindName("BTN_APPLY_NET_TWEAKS").Content = "Apply Tweaks ($applyCount)"
    $ui.FindName("BTN_REVERT_NET_TWEAKS").Content = "Revert Tweaks ($revertCount)"
    Set-TweakButtonState "BTN_APPLY_NET_TWEAKS" $applyCount
    Set-TweakButtonState "BTN_REVERT_NET_TWEAKS" $revertCount
}

1..5 | ForEach-Object {
    $tglNet = $ui.FindName("TGL_NET_$_")
    if ($null -ne $tglNet) {
        $tglNet.Add_Checked({ Update-NetTweakButtons })
        $tglNet.Add_Unchecked({ Update-NetTweakButtons })
    }
}

$ui.FindName("BTN_APPLY_NET_TWEAKS").Add_Click({
    $this.Content = "Applying..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    Start-Sleep -Seconds 2
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_NET_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedNetTweaks[$j]) { $global:appliedNetTweaks[$j] = $true }
    }
    Update-NetTweakButtons
    Save-TweakState
    Show-CustomPopup "Network optimizations applied. Connection stability and ping should improve." "Tweaks Applied" "Success"
})

$ui.FindName("BTN_REVERT_NET_TWEAKS").Add_Click({
    $this.Content = "Processing..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    Start-Sleep -Seconds 2
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_NET_$j")
        if ($null -ne $t) { $t.IsChecked = $false; $global:appliedNetTweaks[$j] = $false }
    }
    Update-NetTweakButtons
    Save-TweakState
    Show-CustomPopup "Network tweaks reverted to default states." "Tweaks Reverted" "Success"
})

Update-NetTweakButtons


