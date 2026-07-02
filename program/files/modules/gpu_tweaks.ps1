# GPU Tweaks Module
$global:gpuTweakItems = @()
for ($i = 1; $i -le 5; $i++) { $global:gpuTweakItems += $ui.FindName("ITEM_GPU_$i") }
$global:gpuLeftPanel = $global:gpuTweakItems[0].Parent
$global:gpuRightPanel = $global:gpuTweakItems[3].Parent

$ui.FindName("INP_GPUTWEAKS_SEARCH").Add_GotKeyboardFocus({ 
        if ($this.Text -eq "Search GPU tweaks...") { $this.Text = ""; $this.Foreground = "#FFF" } 
    })
$ui.FindName("INP_GPUTWEAKS_SEARCH").Add_LostKeyboardFocus({ 
        if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text = "Search GPU tweaks..."; $this.Foreground = "#949BAA" } 
    })
$ui.FindName("INP_GPUTWEAKS_SEARCH").Add_TextChanged({
        $q = $this.Text.ToLower().Trim()
        if ($q -eq 'search gpu tweaks...') { $q = '' }
        $titles = @{}
        $titles[1] = 'enable hardware gpu scheduling'
        $titles[2] = 'disable multi-plane overlay mpo'
        $titles[3] = 'optimize gpu priority'
        $titles[4] = 'enable ultra low latency mode'
        $titles[5] = 'optimize power management'
        $global:gpuLeftPanel.Children.Clear()
        $global:gpuRightPanel.Children.Clear()
        $matched = @()
        for ($i = 0; $i -lt $global:gpuTweakItems.Count; $i++) {
            if ($q -eq '' -or $titles[$i + 1].Contains($q)) {
                $matched += $global:gpuTweakItems[$i]
            }
        }
        $half = [math]::Ceiling($matched.Count / 2)
        for ($j = 0; $j -lt $matched.Count; $j++) {
            if ($j -lt $half) { $global:gpuLeftPanel.Children.Add($matched[$j]) }
            else { $global:gpuRightPanel.Children.Add($matched[$j]) }
        }
        $sv = $ui.FindName('SCROLL_GPUTWEAKS')
        if ($null -ne $sv) { $sv.ScrollToTop() }
    })

# GPU Tweaks Info Buttons
1..5 | ForEach-Object {
    $btnGpuInfo = $ui.FindName("BTN_INFO_GPU_$_")
    if ($null -ne $btnGpuInfo) {
        $btnGpuInfo.Add_MouseEnter({ 
                $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#00B4DB" }
            })
        $btnGpuInfo.Add_MouseLeave({ 
                $tb = [System.Windows.Controls.TextBlock]$this.Child; if ($tb) { $tb.Foreground = "#949BAA" }
            })
        $btnGpuInfo.Add_PreviewMouseLeftButtonDown({
                $tb = [System.Windows.Controls.TextBlock]$this.Child
                if ($tb) { $tb.Foreground = "#00B4DB" }
            })
    }
}

# State Tracking - per sub-category
$global:currentGpuSubCat = "General"
$global:appliedGpuTweaks = @{
    General = @{}
    NVIDIA  = @{}
    AMD     = @{}
    Intel   = @{}
}
foreach ($cat in @('General','NVIDIA','AMD','Intel')) {
    for ($k = 1; $k -le 5; $k++) { $global:appliedGpuTweaks[$cat][$k] = $false }
}

function Update-GpuTweakButtons {
    $cat = $global:currentGpuSubCat
    $applyCount = 0; $revertCount = 0
    for ($j = 1; $j -le 5; $j++) { 
        $t = $ui.FindName("TGL_GPU_$j")
        if ($null -ne $t -and $t.IsChecked -and -not $global:appliedGpuTweaks[$cat][$j]) { $applyCount++ }
        if ($null -ne $t -and -not $t.IsChecked -and $global:appliedGpuTweaks[$cat][$j]) { $revertCount++ }
    }
    $ui.FindName("BTN_APPLY_GPU_TWEAKS").Content = "Apply Tweaks ($applyCount)"
    $ui.FindName("BTN_REVERT_GPU_TWEAKS").Content = "Revert Tweaks ($revertCount)"
    Set-TweakButtonState "BTN_APPLY_GPU_TWEAKS" $applyCount
    Set-TweakButtonState "BTN_REVERT_GPU_TWEAKS" $revertCount
}

1..5 | ForEach-Object {
    $tglGpu = $ui.FindName("TGL_GPU_$_")
    if ($null -ne $tglGpu) {
        $tglGpu.Add_Checked({ Update-GpuTweakButtons })
        $tglGpu.Add_Unchecked({ Update-GpuTweakButtons })
    }
}

$ui.FindName("BTN_APPLY_GPU_TWEAKS").Add_Click({
        $cat = $global:currentGpuSubCat
        $this.Content = "Processing..."
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action] {}, 'Render')
        Start-Sleep -Seconds 2
        for ($j = 1; $j -le 5; $j++) { 
            $t = $ui.FindName("TGL_GPU_$j")
            if ($null -ne $t -and $t.IsChecked -and -not $global:appliedGpuTweaks[$cat][$j]) { $global:appliedGpuTweaks[$cat][$j] = $true }
        }
        Update-GpuTweakButtons
        Save-TweakState
        Show-CustomPopup "GPU optimizations applied successfully. Some changes may require a restart." "Tweaks Applied" "Success"
    })

$ui.FindName("BTN_REVERT_GPU_TWEAKS").Add_Click({
        $cat = $global:currentGpuSubCat
        $this.Content = "Processing..."
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action] {}, 'Render')
        Start-Sleep -Seconds 2
        for ($j = 1; $j -le 5; $j++) { 
            $t = $ui.FindName("TGL_GPU_$j")
            if ($null -ne $t) { $t.IsChecked = $false; $global:appliedGpuTweaks[$cat][$j] = $false }
        }
        Update-GpuTweakButtons
        Save-TweakState
        Show-CustomPopup "GPU tweaks reverted to default states." "Tweaks Reverted" "Success"
    })

function Invoke-GpuSubViewIn {
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

function Invoke-GpuSubViewOut {
    param($element)
    if ($null -eq $element) { return }
    $element.IsHitTestVisible = $false
    [System.Windows.Controls.Panel]::SetZIndex($element, 1)
    $animY = New-Object System.Windows.Media.Animation.DoubleAnimation -Property @{ From = 0; To = -10; Duration = "0:0:0.16"; EasingFunction = (New-Object System.Windows.Media.Animation.CubicEase -Property @{ EasingMode = 'EaseIn' }) }
    $animOp = New-Object System.Windows.Media.Animation.DoubleAnimation -Property @{ From = 1; To = 0; Duration = "0:0:0.12" }
    if ($element.RenderTransform) { $element.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $animY) }
    $element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $animOp)
}

function Hide-GpuSubViewAfterTransition {
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
    if ($null -eq $script:GpuTransitionTimers) { $script:GpuTransitionTimers = @() }
    $script:GpuTransitionTimers += $timer
    $timer.Start()
}

function Invoke-GpuCategoryPopupAnimation {
    $main = $ui.FindName("VIEW_GPUTWEAKS_MAIN")
    if ($null -ne $main) {
        Animate-SectionItems -viewElem $main
    }
}

function Show-GpuTweakList {
    param([string]$title)
    $ui.FindName("TXT_GPU_SUBCAT_TITLE").Text = $title
    $main = $ui.FindName("VIEW_GPUTWEAKS_MAIN")
    $list = $ui.FindName("VIEW_GPU_TWEAKLIST")
    if ($null -ne $list) {
        $list.Visibility = 'Visible'
        $list.IsHitTestVisible = $true
        [System.Windows.Controls.Panel]::SetZIndex($list, 2)
        $list.Opacity = 0
        if ($list.RenderTransform) { $list.RenderTransform.Y = 15 }
        $sv = $ui.FindName('SCROLL_GPUTWEAKS')
        if ($null -ne $sv) { $sv.ScrollToTop() }
    }
    if ($null -ne $main) {
        $main.IsHitTestVisible = $false
        [System.Windows.Controls.Panel]::SetZIndex($main, 1)
    }
    Invoke-GpuSubViewIn $list
    Animate-SectionItems -viewElem $list
    Invoke-GpuSubViewOut $main
    Hide-GpuSubViewAfterTransition $main
}

function Show-GpuCategories {
    $main = $ui.FindName("VIEW_GPUTWEAKS_MAIN")
    $list = $ui.FindName("VIEW_GPU_TWEAKLIST")
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
    Invoke-GpuSubViewIn $main
    Invoke-GpuCategoryPopupAnimation
    Invoke-GpuSubViewOut $list
    Hide-GpuSubViewAfterTransition $list
}

# --- NEW NAVIGATION LOGIC ---
$ui.FindName("BTN_CAT_GPU_GENERAL").Add_PreviewMouseLeftButtonDown({
        $global:currentGpuSubCat = "General"
        for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_GPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedGpuTweaks["General"][$j] } }
        Show-GpuTweakList "General GPU Tweaks"
    })

$ui.FindName("BTN_CAT_GPU_NVIDIA").Add_PreviewMouseLeftButtonDown({
        if ($global:GpuVendorIsNvidia -eq $false) {
            $global:ModalContinueAction = {
                $global:currentGpuSubCat = "NVIDIA"
                for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_GPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedGpuTweaks["NVIDIA"][$j] } }
                Show-GpuTweakList "NVIDIA GPU Tweaks"
            }
            Show-CustomPopup "Vendor mismatch detected. You are trying to access NVIDIA tweaks but an AMD/Intel/Other GPU was detected." "Vendor Mismatch" "Warning" -ShowContinue
            return
        }
        $global:currentGpuSubCat = "NVIDIA"
        for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_GPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedGpuTweaks["NVIDIA"][$j] } }
        Show-GpuTweakList "NVIDIA GPU Tweaks"
    })

$ui.FindName("BTN_CAT_GPU_AMD").Add_PreviewMouseLeftButtonDown({
        if ($global:GpuVendorIsAmd -eq $false) {
            $global:ModalContinueAction = {
                $global:currentGpuSubCat = "AMD"
                for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_GPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedGpuTweaks["AMD"][$j] } }
                Show-GpuTweakList "AMD GPU Tweaks"
            }
            Show-CustomPopup "Vendor mismatch detected. You are trying to access AMD tweaks but an NVIDIA/Intel/Other GPU was detected." "Vendor Mismatch" "Warning" -ShowContinue
            return
        }
        $global:currentGpuSubCat = "AMD"
        for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_GPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedGpuTweaks["AMD"][$j] } }
        Show-GpuTweakList "AMD GPU Tweaks"
    })

$ui.FindName("BTN_CAT_GPU_INTEL").Add_PreviewMouseLeftButtonDown({
        if ($global:GpuVendorIsIntel -eq $false) {
            $global:ModalContinueAction = {
                $global:currentGpuSubCat = "Intel"
                for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_GPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedGpuTweaks["Intel"][$j] } }
                Show-GpuTweakList "INTEL GPU Tweaks"
            }
            Show-CustomPopup "Vendor mismatch detected. You are trying to access Intel tweaks but an NVIDIA/AMD/Other GPU was detected." "Vendor Mismatch" "Warning" -ShowContinue
            return
        }
        $global:currentGpuSubCat = "Intel"
        for ($j=1; $j -le 5; $j++) { $t = $ui.FindName("TGL_GPU_$j"); if ($null -ne $t) { $t.IsChecked = $global:appliedGpuTweaks["Intel"][$j] } }
        Show-GpuTweakList "INTEL GPU Tweaks"
    })

$ui.FindName("BTN_GPU_BACK").Add_Click({
        Show-GpuCategories
    })

Update-GpuTweakButtons



