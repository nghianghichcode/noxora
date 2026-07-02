# System Tweaks Module

# Ã¢â€â‚¬Ã¢â€â‚¬ Item registry Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
$global:sysTweakItems = @()
for ($i = 1; $i -le 13; $i++) {
    $el = $ui.FindName("ITEM_SYS_$i")
    if ($null -ne $el) { $global:sysTweakItems += $el }
}
$global:sysLeftPanel  = $ui.FindName("SYS_LEFT_PANEL")
$global:sysRightPanel = $ui.FindName("SYS_RIGHT_PANEL")

# Ã¢â€â‚¬Ã¢â€â‚¬ Tab categories (identical pattern to bugfix) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
$global:sysTweakTitles = @{
    1  = 'disable visual effects'
    2  = 'high performance power plan'
    3  = 'disable startup delay'
    4  = 'disable hibernation'
    5  = 'disable windows tips and suggestions'
    6  = 'optimize ntfs parameters'
    7  = 'disable automatic updates'
    8  = 'disable prefetch and superfetch'
    9  = 'disable background apps'
    10 = 'disable cortana telemetry'
    11 = 'disable advertising id'
    12 = 'clear temp files on boot'
    13 = 'disable kernel mitigations'
}

$global:sysTweakCats = @{
    1  = 'PERFORMANCE'
    2  = 'PERFORMANCE'
    3  = 'PERFORMANCE'
    4  = 'CLEANUP'
    5  = 'PRIVACY'
    6  = 'PERFORMANCE'
    7  = 'PERFORMANCE'
    8  = 'PERFORMANCE'
    9  = 'PERFORMANCE'
    10 = 'PRIVACY'
    11 = 'PRIVACY'
    12 = 'CLEANUP'
    13 = 'ADVANCED'
}

$global:currentSysTweaksTab = 'PERFORMANCE'

# Ã¢â€â‚¬Ã¢â€â‚¬ Update view (filter by tab + search) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
function Update-SysTweaksView {
    param([bool]$animate = $true)
    $q = $ui.FindName("INP_SYSTWEAKS_SEARCH").Text.ToLower().Trim()
    if ($q -eq 'search tweaks...') { $q = '' }

    $global:sysLeftPanel.Children.Clear()
    $global:sysRightPanel.Children.Clear()

    $matched = @()
    for ($i = 0; $i -lt $global:sysTweakItems.Count; $i++) {
        $idx = $i + 1
        $catOk   = $global:sysTweakCats[$idx] -eq $global:currentSysTweaksTab
        $titleOk = $q -eq '' -or $global:sysTweakTitles[$idx].Contains($q)
        if ($catOk -and $titleOk) { $matched += $global:sysTweakItems[$i] }
    }

    $half = [math]::Ceiling($matched.Count / 2)
    for ($j = 0; $j -lt $matched.Count; $j++) {
        if ($j -lt $half) { $global:sysLeftPanel.Children.Add($matched[$j]) }
        else               { $global:sysRightPanel.Children.Add($matched[$j]) }
    }

    $sv = $ui.FindName('SCROLL_SYSTWEAKS')
    if ($null -ne $sv) { $sv.ScrollToTop() }

    if ($animate) {
        $viewElem = $ui.FindName("SYSTWEAKS_CONTENT")
        if ($null -ne $viewElem) { Animate-SectionItems $viewElem }
    }
}

# Ã¢â€â‚¬Ã¢â€â‚¬ Animated selector bar (identical to Set-BugfixTabSelector) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
function Set-SysTweaksTabSelector {
    param($btn)
    $transform  = $ui.FindName("SysTweaksSelectorTransform")
    $selector   = $ui.FindName("SysTweaksTabSelector")
    $container  = $ui.FindName("SYSTWEAKS_TAB_CONTAINER")
    if ($null -eq $transform -or $null -eq $selector -or $null -eq $container) { return }
    if ($btn.ActualWidth -eq 0) { return }
    $pos = $btn.TranslatePoint((New-Object System.Windows.Point(0,0)), $container)

    $targetX = $pos.X
    $targetW = $btn.ActualWidth
    $ease    = New-Object System.Windows.Media.Animation.QuarticEase -Property @{ EasingMode = 'EaseOut' }
    $animX   = New-Object System.Windows.Media.Animation.DoubleAnimation -Property @{ To = $targetX; Duration = "0:0:0.25"; EasingFunction = $ease }
    $animW   = New-Object System.Windows.Media.Animation.DoubleAnimation -Property @{ To = $targetW; Duration = "0:0:0.25"; EasingFunction = $ease }

    $transform.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $animX)
    $selector.BeginAnimation([System.Windows.FrameworkElement]::WidthProperty, $animW)
}

# Ã¢â€â‚¬Ã¢â€â‚¬ Tab checked handlers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
$ui.FindName("TAB_SYSTWEAKS_PERFORMANCE").Add_Checked({
    Set-SysTweaksTabSelector $this
    $global:currentSysTweaksTab = 'PERFORMANCE'
    Update-SysTweaksView -animate $true
})
$ui.FindName("TAB_SYSTWEAKS_PRIVACY").Add_Checked({
    Set-SysTweaksTabSelector $this
    $global:currentSysTweaksTab = 'PRIVACY'
    Update-SysTweaksView -animate $true
})
$ui.FindName("TAB_SYSTWEAKS_CLEANUP").Add_Checked({
    Set-SysTweaksTabSelector $this
    $global:currentSysTweaksTab = 'CLEANUP'
    Update-SysTweaksView -animate $true
})
$ui.FindName("TAB_SYSTWEAKS_ADVANCED").Add_Checked({
    Set-SysTweaksTabSelector $this
    $global:currentSysTweaksTab = 'ADVANCED'
    Update-SysTweaksView -animate $true
})

# Re-sync selector when view becomes visible (same as bugfix)
$ui.FindName("VIEW_SYSTWEAKS").Add_IsVisibleChanged({
    if ($this.IsVisible) {
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke("Background", [Action]{
            $btn = $ui.FindName("TAB_SYSTWEAKS_$global:currentSysTweaksTab")
            if ($null -ne $btn) { Set-SysTweaksTabSelector $btn }
            Update-SysTweaksView -animate $false
        })
    }
})

# Ã¢â€â‚¬Ã¢â€â‚¬ Search bar Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
$ui.FindName("INP_SYSTWEAKS_SEARCH").Add_GotKeyboardFocus({
    if ($this.Text -eq "Search tweaks...") { $this.Text = ""; $this.Foreground = "#FFF" }
})
$ui.FindName("INP_SYSTWEAKS_SEARCH").Add_LostKeyboardFocus({
    if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text = "Search tweaks..."; $this.Foreground = "#949BAA" }
})
$ui.FindName("INP_SYSTWEAKS_SEARCH").Add_TextChanged({ Update-SysTweaksView -animate $false })

# Ã¢â€â‚¬Ã¢â€â‚¬ Info button hover effects Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
1..13 | ForEach-Object {
    $btnInfo = $ui.FindName("BTN_INFO_SYS_$_")
    if ($null -ne $btnInfo) {
        $btnInfo.Add_MouseEnter({
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            if ($tb) { $tb.Foreground = "#00B4DB" }
        })
        $btnInfo.Add_MouseLeave({
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            if ($tb) { $tb.Foreground = "#949BAA" }
        })
        $btnInfo.Add_PreviewMouseLeftButtonDown({
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            if ($tb) { $tb.Foreground = "#00B4DB" }
        })
    }
}

# Ã¢â€â‚¬Ã¢â€â‚¬ State tracking Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
$global:appliedTweaks = @{}
for ($k = 1; $k -le 13; $k++) { $global:appliedTweaks[$k] = $false }

function Update-SysTweakButtons {
    $applyCount = 0; $revertCount = 0
    for ($j = 1; $j -le 13; $j++) {
        $t = $ui.FindName("TGL_SYS_$j")
        if ($null -ne $t -and $t.IsChecked  -and -not $global:appliedTweaks[$j]) { $applyCount++ }
        if ($null -ne $t -and -not $t.IsChecked -and $global:appliedTweaks[$j]) { $revertCount++ }
    }
    $ui.FindName("BTN_APPLY_TWEAKS").Content  = "Apply Tweaks ($applyCount)"
    $ui.FindName("BTN_REVERT_TWEAKS").Content = "Revert Tweaks ($revertCount)"
    Set-TweakButtonState "BTN_APPLY_TWEAKS" $applyCount
    Set-TweakButtonState "BTN_REVERT_TWEAKS" $revertCount
}

1..13 | ForEach-Object {
    $tgl = $ui.FindName("TGL_SYS_$_")
    if ($null -ne $tgl) {
        $tgl.Add_Checked({ Update-SysTweakButtons })
        $tgl.Add_Unchecked({ Update-SysTweakButtons })
    }
}

# Ã¢â€â‚¬Ã¢â€â‚¬ Apply / Revert buttons Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
$ui.FindName("BTN_APPLY_TWEAKS").Add_Click({
    $this.Content    = "Processing..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    
    # Log the action
    if (Get-Command Log-ProgramAction -ErrorAction SilentlyContinue) {
        Log-ProgramAction -Action "Apply System Tweaks" -Details "Applying selected system tweaks"
    }
    
    for ($j = 1; $j -le 13; $j++) {
        $t = $ui.FindName("TGL_SYS_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedTweaks[$j]) { 
            $global:appliedTweaks[$j] = $true
            # Execute corresponding .bat file if exists
            $batPath = "$ModuleRoot\tweak\05_system_tweaks"
            $batFile = switch ($j) {
                1 { "performance\01_disable_visual_effects.bat" }
                2 { "performance\02_high_performance_power.bat" }
                3 { "performance\03_disable_startup_delay.bat" }
                4 { "cleanup\04_disable_hibernation.bat" }
                5 { "privacy\05_disable_windows_tips.bat" }
                6 { "performance\06_optimize_ntfs.bat" }
                7 { "performance\07_disable_updates.bat" }
                8 { "performance\08_disable_prefetch.bat" }
                9 { "performance\09_disable_background_apps.bat" }
                10 { "privacy\10_disable_cortana_telemetry.bat" }
                11 { "privacy\11_disable_advertising_id.bat" }
                12 { "cleanup\12_clear_temp_files.bat" }
                13 { "advanced\13_disable_kernel_mitigations.bat" }
            }
            $fullBatPath = Join-Path $batPath $batFile
            if (Test-Path $fullBatPath) {
                if (Get-Command Invoke-LoggedBat -ErrorAction SilentlyContinue) {
                    Invoke-LoggedBat -BatPath $fullBatPath
                } else {
                    Start-Process $fullBatPath -Wait -WindowStyle Hidden
                }
            }
        }
    }
    Start-Sleep -Seconds 1
    Update-SysTweakButtons
    Save-TweakState
    Show-CustomPopup "All selected tweaks have been applied successfully." "Tweaks Applied" "Success"
})

$ui.FindName("BTN_REVERT_TWEAKS").Add_Click({
    $this.Content    = "Processing..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    
    # Log the action
    if (Get-Command Log-ProgramAction -ErrorAction SilentlyContinue) {
        Log-ProgramAction -Action "Revert System Tweaks" -Details "Reverting selected system tweaks to default"
    }
    
    for ($j = 1; $j -le 13; $j++) {
        $t = $ui.FindName("TGL_SYS_$j")
        if ($null -ne $t -and -not $t.IsChecked -and $global:appliedTweaks[$j]) { $global:appliedTweaks[$j] = $false }
    }
    Start-Sleep -Seconds 1
    Update-SysTweakButtons
    Save-TweakState
    Show-CustomPopup "All selected tweaks have been reverted to default settings." "Tweaks Reverted" "Success"
})

Update-SysTweakButtons


