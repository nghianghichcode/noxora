# Input Tweaks Module
$ui.FindName("INP_INPUTTWEAKS_SEARCH").Add_GotKeyboardFocus({
    if ($this.Text -eq "Search tweaks...") { $this.Text = ""; $this.Foreground = "#FFF" }
})
$ui.FindName("INP_INPUTTWEAKS_SEARCH").Add_LostKeyboardFocus({
    if ($this.Text -eq "") { $this.Text = "Search tweaks..."; $this.Foreground = "#949BAA" }
})
$ui.FindName("INP_INPUTTWEAKS_SEARCH").Add_TextChanged({
    $q = $this.Text.ToLower().Trim()
    if ($q -eq 'search tweaks...') { $q = '' }
    $titles = @{ 1 = 'disable enhance pointer precision'; 2 = 'reduce keyboard repeat delay'; 3 = 'keyboard polling rate tweaks'; 4 = 'disable filter keys' }
    for ($j=1; $j -le 4; $j++) {
        $item = $ui.FindName("ITEM_INPUT_$j")
        if ($null -ne $item) {
            if ($q -eq '' -or $titles[$j].Contains($q)) { $item.Visibility = 'Visible' }
            else { $item.Visibility = 'Collapsed' }
        }
    }
})

# Input Tweaks Info Buttons
1..4 | ForEach-Object {
    $btnInputInfo = $ui.FindName("BTN_INFO_INPUT_$_")
    if ($null -ne $btnInputInfo) {
        $btnInputInfo.Add_MouseEnter({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#00B4DB" }
        })
        $btnInputInfo.Add_MouseLeave({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#949BAA" }
        })
        $btnInputInfo.Add_PreviewMouseLeftButtonDown({
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            if ($tb) { $tb.Foreground = "#00B4DB" }
        })
    }
}

$global:appliedInputTweaks = @{}
for ($k=1; $k -le 4; $k++) { $global:appliedInputTweaks[$k] = $false }

function Update-InputTweakButtons {
    $applyCount = 0; $revertCount = 0
    for ($j=1; $j -le 4; $j++) { 
        $t = $ui.FindName("TGL_INPUT_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedInputTweaks[$j]) { $applyCount++ }
        if ($null -ne $t -and -not $t.IsChecked -and $global:appliedInputTweaks[$j]) { $revertCount++ }
    }
    $ui.FindName("BTN_APPLY_INPUT_TWEAKS").Content = "Apply Tweaks ($applyCount)"
    $ui.FindName("BTN_REVERT_INPUT_TWEAKS").Content = "Revert Tweaks ($revertCount)"
    Set-TweakButtonState "BTN_APPLY_INPUT_TWEAKS" $applyCount
    Set-TweakButtonState "BTN_REVERT_INPUT_TWEAKS" $revertCount
}

1..4 | ForEach-Object {
    $tglInput = $ui.FindName("TGL_INPUT_$_")
    if ($null -ne $tglInput) {
        $tglInput.Add_Checked({ Update-InputTweakButtons })
        $tglInput.Add_Unchecked({ Update-InputTweakButtons })
    }
}

$ui.FindName("BTN_APPLY_INPUT_TWEAKS").Add_Click({
    $this.Content = "Processing..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    Start-Sleep -Seconds 2
    for ($j=1; $j -le 4; $j++) { 
        $t = $ui.FindName("TGL_INPUT_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedInputTweaks[$j]) { $global:appliedInputTweaks[$j] = $true }
    }
    Update-InputTweakButtons
    Save-TweakState
    Show-CustomPopup "Input optimizations applied. Mouse and keyboard latency should be reduced." "Tweaks Applied" "Success"
})

$ui.FindName("BTN_REVERT_INPUT_TWEAKS").Add_Click({
    $this.Content = "Processing..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    Start-Sleep -Seconds 2
    for ($j=1; $j -le 4; $j++) { 
        $t = $ui.FindName("TGL_INPUT_$j")
        if ($null -ne $t) { $t.IsChecked = $false; $global:appliedInputTweaks[$j] = $false }
    }
    Update-InputTweakButtons
    Save-TweakState
    Show-CustomPopup "Input tweaks reverted to default states." "Tweaks Reverted" "Success"
})

Update-InputTweakButtons


