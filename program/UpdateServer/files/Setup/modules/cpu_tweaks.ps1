# CPU Tweaks Module
$global:cpuTweakItems = @()
for ($i=1; $i -le 5; $i++) { $global:cpuTweakItems += $ui.FindName("ITEM_CPU_$i") }
$global:cpuLeftPanel = $global:cpuTweakItems[0].Parent
$global:cpuRightPanel = $global:cpuTweakItems[3].Parent

$ui.FindName("INP_CPUTWEAKS_SEARCH").Add_GotKeyboardFocus({ 
    if ($this.Text -eq "Search CPU tweaks...") { $this.Text = ""; $this.Foreground = "#FFF" } 
})
$ui.FindName("INP_CPUTWEAKS_SEARCH").Add_LostKeyboardFocus({ 
    if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text = "Search CPU tweaks..."; $this.Foreground = "#949BAA" } 
})
$ui.FindName("INP_CPUTWEAKS_SEARCH").Add_TextChanged({
    $q = $this.Text.ToLower().Trim()
    if ($q -eq 'search cpu tweaks...') { $q = '' }
    $titles = @{}
    $titles[1] = 'disable core parking'
    $titles[2] = 'disable c-states idle states'
    $titles[3] = 'optimize priority separation'
    $titles[4] = 'disable cpu meltdown patches'
    $titles[5] = 'enable energy performance preference'
    $global:cpuLeftPanel.Children.Clear()
    $global:cpuRightPanel.Children.Clear()
    $matched = @()
    for ($i=0; $i -lt $global:cpuTweakItems.Count; $i++) {
        if ($q -eq '' -or $titles[$i+1].Contains($q)) {
            $matched += $global:cpuTweakItems[$i]
        }
    }
    $half = [math]::Ceiling($matched.Count / 2)
    for ($j=0; $j -lt $matched.Count; $j++) {
        if ($j -lt $half) { $global:cpuLeftPanel.Children.Add($matched[$j]) }
        else { $global:cpuRightPanel.Children.Add($matched[$j]) }
    }
    $sv = $ui.FindName('SCROLL_CPUTWEAKS')
    if ($null -ne $sv) { $sv.ScrollToTop() }
})

# CPU Tweaks Info Buttons
1..5 | ForEach-Object {
    $btnCpuInfo = $ui.FindName("BTN_INFO_CPU_$_")
    if ($null -ne $btnCpuInfo) {
        $btnCpuInfo.Add_MouseEnter({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#00B4DB" }
        })
        $btnCpuInfo.Add_MouseLeave({ 
            $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#949BAA" }
        })
        $btnCpuInfo.Add_PreviewMouseLeftButtonDown({
            $tb = [System.Windows.Controls.TextBlock]$this.Child
            if ($tb) { $tb.Foreground = "#00B4DB" }
        })
    }
}

# State Tracking - per sub-category
$global:currentCpuSubCat = "General"
$global:appliedCpuTweaks = @{
    General = @{}
    AMD     = @{}
    Intel   = @{}
}
foreach ($cat in @('General','AMD','Intel')) {
    for ($k=1; $k -le 5; $k++) { $global:appliedCpuTweaks[$cat][$k] = $false }
}

function Update-CpuTweakButtons {
    $cat = $global:currentCpuSubCat
    $applyCount = 0; $revertCount = 0
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_CPU_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedCpuTweaks[$cat][$j]) { $applyCount++ }
        if ($null -ne $t -and -not $t.IsChecked -and $global:appliedCpuTweaks[$cat][$j]) { $revertCount++ }
    }
    $ui.FindName("BTN_APPLY_CPU_TWEAKS").Content = "Apply Tweaks ($applyCount)"
    $ui.FindName("BTN_REVERT_CPU_TWEAKS").Content = "Revert Tweaks ($revertCount)"
    Set-TweakButtonState "BTN_APPLY_CPU_TWEAKS" $applyCount
    Set-TweakButtonState "BTN_REVERT_CPU_TWEAKS" $revertCount
}

1..5 | ForEach-Object {
    $tgl = $ui.FindName("TGL_CPU_$_")
    if ($null -ne $tgl) {
        $tgl.Add_Checked({ Update-CpuTweakButtons })
        $tgl.Add_Unchecked({ Update-CpuTweakButtons })
    }
}

$ui.FindName("BTN_APPLY_CPU_TWEAKS").Add_Click({
    $cat = $global:currentCpuSubCat
    $this.Content = "Processing..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    Start-Sleep -Seconds 2
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_CPU_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedCpuTweaks[$cat][$j]) { $global:appliedCpuTweaks[$cat][$j] = $true }
    }
    Update-CpuTweakButtons
    Save-TweakState
    Show-CustomPopup "All selected CPU modifications applied." "Tweaks Applied" "Success"
})

$ui.FindName("BTN_REVERT_CPU_TWEAKS").Add_Click({
    $cat = $global:currentCpuSubCat
    $this.Content = "Processing..."
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, 'Render')
    Start-Sleep -Seconds 2
    for ($j=1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_CPU_$j")
        if ($null -ne $t -and -not $t.IsChecked -and $global:appliedCpuTweaks[$cat][$j]) {
            $global:appliedCpuTweaks[$cat][$j] = $false
        }
    }
    Update-CpuTweakButtons
    Save-TweakState
    Show-CustomPopup "CPU tweaks reverted to default safe states." "Tweaks Reverted" "Success"
})
function Invoke-CpuSubViewIn {
    param($element)
    if ($null -eq $element) { return }
    $element.Visibility = 'Visible'
    $element.IsHitTestVisible = $true
    [System.Windows.Controls.Panel]::SetZIndex($element, 2)
    $element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
    if ($element.RenderTransform) {
        $element.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $null)
        $element.RenderTransform.Y = 15
    }
    $animY = New-Object System.Windows.Media.Animation.DoubleAnimation -Property @{ From = 15; To = 0; Duration = "0:0:0.2"; EasingFunction = (New-Object System.Windows.Media.Animation.QuarticEase -Property @{ EasingMode = 'EaseOut' }) }
    $animOp = New-Object System.Windows.Media.Animation.DoubleAnimation -Property @{ From = 0; To = 1; Duration = "0:0:0.15" }
    if ($element.RenderTransform) { $element.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $animY) }
    $element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $animOp)
}

function Invoke-CpuSubViewOut {
    param($element)
    if ($null -eq $element) { return }
    $element.IsHitTestVisible = $false
    [System.Windows.Controls.Panel]::SetZIndex($element, 1)
    $animY = New-Object System.Windows.Media.Animation.DoubleAnimation -Property @{ From = 0; To = -10; Duration = "0:0:0.16"; EasingFunction = (New-Object System.Windows.Media.Animation.CubicEase -Property @{ EasingMode = 'EaseIn' }) }
    $animOp = New-Object System.Windows.Media.Animation.DoubleAnimation -Property @{ From = 1; To = 0; Duration = "0:0:0.12" }
    if ($element.RenderTransform) { $element.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $animY) }
    $element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $animOp)
}

function Hide-CpuSubViewAfterTransition {
    param($element)
    if ($null -eq $element) { return }
    $element.IsHitTestVisible = $false
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(230)
    $timer.Add_Tick({
        $this.Stop()
        if ($null -ne $element) {
            $element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
            if ($element.RenderTransform) {
                $element.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $null)
                $element.RenderTransform.Y = 0
            }
            $element.Opacity = 0
            $element.IsHitTestVisible = $false
            $element.Visibility = 'Hidden'
        }
    })
    if ($null -eq $script:CpuTransitionTimers) { $script:CpuTransitionTimers = @() }
    $script:CpuTransitionTimers += $timer
    $timer.Start()
}

function Invoke-CpuCategoryPopupAnimation {
    $main = $ui.FindName("VIEW_CPUTWEAKS_MAIN")
    if ($null -ne $main) {
        Animate-SectionItems -viewElem $main
    }
}

function Show-CpuTweakList {
    param([string]$title)
    $ui.FindName("TXT_CPU_SUBCAT_TITLE").Text = $title
    $main = $ui.FindName("VIEW_CPUTWEAKS_MAIN")
    $list = $ui.FindName("VIEW_CPU_TWEAKLIST")
    if ($null -ne $list) {
        $list.Visibility = 'Visible'
        $list.IsHitTestVisible = $true
        [System.Windows.Controls.Panel]::SetZIndex($list, 2)
        $list.Opacity = 0
        if ($list.RenderTransform) { $list.RenderTransform.Y = 15 }
        $sv = $ui.FindName('SCROLL_CPUTWEAKS')
        if ($null -ne $sv) { $sv.ScrollToTop() }
    }
    if ($null -ne $main) {
        $main.IsHitTestVisible = $false
        [System.Windows.Controls.Panel]::SetZIndex($main, 1)
    }
    Invoke-CpuSubViewIn $list
    Animate-SectionItems -viewElem $list
    Invoke-CpuSubViewOut $main
    Hide-CpuSubViewAfterTransition $main
}

function Show-CpuCategories {
    $main = $ui.FindName("VIEW_CPUTWEAKS_MAIN")
    $list = $ui.FindName("VIEW_CPU_TWEAKLIST")
    if ($null -ne $main) {
        $main.Visibility = 'Visible'
        $main.IsHitTestVisible = $true
        [System.Windows.Controls.Panel]::SetZIndex($main, 2)
        $main.Opacity = 0
        if ($main.RenderTransform) { $main.RenderTransform.Y = 15 }
    }
    if ($null -ne $list) {
        $list.IsHitTestVisible = $false
        [System.Windows.Controls.Panel]::SetZIndex($list, 1)
    }
    Invoke-CpuSubViewIn $main
    Invoke-CpuCategoryPopupAnimation
    Invoke-CpuSubViewOut $list
    Hide-CpuSubViewAfterTransition $list
}

# --- NEW NAVIGATION LOGIC ---
$ui.FindName("BTN_CAT_CPU_GENERAL").Add_PreviewMouseLeftButtonDown({
    $global:currentCpuSubCat = "General"
    # Restore toggle states for this sub-category
    for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_CPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedCpuTweaks["General"][$j] } }
    Show-CpuTweakList "General CPU Tweaks"
})

$ui.FindName("BTN_CAT_CPU_AMD").Add_PreviewMouseLeftButtonDown({
    if ($global:CpuVendorIsAmd -eq $false) {
        $global:ModalContinueAction = {
            $global:currentCpuSubCat = "AMD"
            for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_CPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedCpuTweaks["AMD"][$j] } }
            Show-CpuTweakList "AMD CPU Tweaks"
        }
        Show-CustomPopup "Vendor mismatch detected. You are trying to access AMD tweaks but an Intel/Other CPU was detected. I am not responsible for any issues related to unstable or problems related to CPU proceed at your own risk" "Vendor Mismatch" "CpuWarning" -ShowContinue
        return
    }
    $global:currentCpuSubCat = "AMD"
    for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_CPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedCpuTweaks["AMD"][$j] } }
    Show-CpuTweakList "AMD CPU Tweaks"
})

$ui.FindName("BTN_CAT_CPU_INTEL").Add_PreviewMouseLeftButtonDown({
    if ($global:CpuVendorIsAmd -eq $true) {
        $global:ModalContinueAction = {
            $global:currentCpuSubCat = "Intel"
            for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_CPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedCpuTweaks["Intel"][$j] } }
            Show-CpuTweakList "INTEL CPU Tweaks"
        }
        Show-CustomPopup "Vendor mismatch detected. You are trying to access Intel tweaks but an AMD CPU was detected. I am not responsible for any issues related to unstable or problems related to CPU proceed at your own risk" "Vendor Mismatch" "CpuWarning" -ShowContinue
        return
    }
    $global:currentCpuSubCat = "Intel"
    for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_CPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedCpuTweaks["Intel"][$j] } }
    Show-CpuTweakList "INTEL CPU Tweaks"
})

$ui.FindName("BTN_CPU_BACK").Add_Click({
    Show-CpuCategories
})

Update-CpuTweakButtons




