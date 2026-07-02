# Game Performance Module - Games, Launchers and Software
$global:gamePerfCards = @()
$global:gamePerfLauncherCards = @()
$global:gamePerfSoftwareCards = @()
$global:gamesGrid = $ui.FindName('GAMES_OPTIONS_LIST')
$global:launchersGrid = $ui.FindName('LAUNCHERS_OPTIONS_LIST')
$global:softwareGrid = $ui.FindName('SOFTWARE_OPTIONS_LIST')

# Initialize game cards
for ($i=1; $i -le 12; $i++) { 
    $global:gamePerfCards += $ui.FindName("CARD_GAME_$i") 
}

# Initialize launcher cards
for ($i=1; $i -le 8; $i++) { 
    $global:gamePerfLauncherCards += $ui.FindName("CARD_LAUNCHER_$i") 
}

# Initialize software cards
for ($i=1; $i -le 6; $i++) { 
    $global:gamePerfSoftwareCards += $ui.FindName("CARD_SOFTWARE_$i") 
}

# Games Data Collection
$global:gamesData = @{
    1 = @{ Name = "Counter-Strike 2"; Executable = "cs2.exe" }
    2 = @{ Name = "Valorant"; Executable = "VALORANT-Win64-Shipping.exe" }
    3 = @{ Name = "League of Legends"; Executable = "League of Legends.exe" }
    4 = @{ Name = "Fortnite"; Executable = "FortniteClient-Win64-Shipping.exe" }
    5 = @{ Name = "Apex Legends"; Executable = "r5apex.exe" }
    6 = @{ Name = "Call of Duty: Warzone"; Executable = "ModernWarfare.exe" }
    7 = @{ Name = "Minecraft"; Executable = "javaw.exe" }
    8 = @{ Name = "Grand Theft Auto V"; Executable = "GTA5.exe" }
    9 = @{ Name = "Rocket League"; Executable = "RocketLeague.exe" }
    10 = @{ Name = "Overwatch 2"; Executable = "Overwatch.exe" }
    11 = @{ Name = "Dota 2"; Executable = "dota2.exe" }
    12 = @{ Name = "Rainbow Six Siege"; Executable = "RainbowSix.exe" }
}

# Launchers Data Collection
$global:launchersData = @{
    1 = @{ Name = "Steam" }
    2 = @{ Name = "Epic Games Launcher" }
    3 = @{ Name = "EA App" }
    4 = @{ Name = "Ubisoft Connect" }
    5 = @{ Name = "Battle.net" }
    6 = @{ Name = "Riot Client" }
    7 = @{ Name = "Xbox App" }
    8 = @{ Name = "GOG Galaxy" }
}

# Software Data Collection
$global:softwareData = @{
    1 = @{ Name = "Adobe Photoshop" }
    2 = @{ Name = "Visual Studio Code" }
    3 = @{ Name = "Blender" }
    4 = @{ Name = "OBS Studio" }
    5 = @{ Name = "Spotify" }
    6 = @{ Name = "Chrome" }
}

$global:currentGamePerfTab = "GAMES"

function Update-GamePerfView {
    param([bool]$animate = $true)
    $q = $ui.FindName("INP_GAMEPERF_SEARCH").Text.ToLower().Trim()
    $placeholder = if ($global:currentGamePerfTab -eq "GAMES") { "Search games..." } elseif ($global:currentGamePerfTab -eq "LAUNCHERS") { "Search launchers..." } else { "Search software..." }
    if ($q -eq $placeholder.ToLower()) { $q = '' }
    
    # Toggle visibility based on current tab
    if ($global:currentGamePerfTab -eq "GAMES") {
        $global:gamesGrid.Visibility = "Visible"
        $global:launchersGrid.Visibility = "Collapsed"
        $global:softwareGrid.Visibility = "Collapsed"
        
        for ($i=0; $i -lt $global:gamePerfCards.Count; $i++) {
            $idx = $i + 1
            if ($q -eq '' -or $global:gamesData[$idx].Name.ToLower().Contains($q)) {
                $global:gamePerfCards[$i].Visibility = "Visible"
            } else {
                $global:gamePerfCards[$i].Visibility = "Collapsed"
            }
        }
    } elseif ($global:currentGamePerfTab -eq "LAUNCHERS") {
        $global:gamesGrid.Visibility = "Collapsed"
        $global:launchersGrid.Visibility = "Visible"
        $global:softwareGrid.Visibility = "Collapsed"
        
        for ($i=0; $i -lt $global:gamePerfLauncherCards.Count; $i++) {
            $idx = $i + 1
            if ($q -eq '' -or $global:launchersData[$idx].Name.ToLower().Contains($q)) {
                $global:gamePerfLauncherCards[$i].Visibility = "Visible"
            } else {
                $global:gamePerfLauncherCards[$i].Visibility = "Collapsed"
            }
        }
    } else {
        $global:gamesGrid.Visibility = "Collapsed"
        $global:launchersGrid.Visibility = "Collapsed"
        $global:softwareGrid.Visibility = "Visible"
        
        for ($i=0; $i -lt $global:gamePerfSoftwareCards.Count; $i++) {
            $idx = $i + 1
            if ($q -eq '' -or $global:softwareData[$idx].Name.ToLower().Contains($q)) {
                $global:gamePerfSoftwareCards[$i].Visibility = "Visible"
            } else {
                $global:gamePerfSoftwareCards[$i].Visibility = "Collapsed"
            }
        }
    }
    
    $sv = $ui.FindName('SCROLL_GAMEPERF')
    if ($null -ne $sv) { $sv.ScrollToTop() }
    
    if ($animate) {
        $viewElem = $ui.FindName("GAMEPERF_CONTENT")
        if ($null -ne $viewElem) {
            Animate-SectionItems $viewElem
        }
    }
}

# Search input handlers
$ui.FindName("INP_GAMEPERF_SEARCH").Add_GotKeyboardFocus({ 
    $placeholder = if ($global:currentGamePerfTab -eq "GAMES") { "Search games..." } elseif ($global:currentGamePerfTab -eq "LAUNCHERS") { "Search launchers..." } else { "Search software..." }
    if ($this.Text -eq $placeholder) { $this.Text = ""; $this.Foreground = "#FFF" } 
})
$ui.FindName("INP_GAMEPERF_SEARCH").Add_LostKeyboardFocus({ 
    $placeholder = if ($global:currentGamePerfTab -eq "GAMES") { "Search games..." } elseif ($global:currentGamePerfTab -eq "LAUNCHERS") { "Search launchers..." } else { "Search software..." }
    if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text = $placeholder; $this.Foreground = "#949BAA" } 
})
$ui.FindName("INP_GAMEPERF_SEARCH").Add_TextChanged({ Update-GamePerfView -animate $false })

# Tab selector function
function Set-GamePerfTabSelector {
    param($btn)
    $transform = $ui.FindName("GamePerfSelectorTransform")
    $selector = $ui.FindName("GamePerfTabSelector")
    $container = $ui.FindName("GAMEPERF_TAB_CONTAINER")
    if ($null -eq $transform -or $null -eq $selector -or $null -eq $container) { return }
    if ($btn.ActualWidth -eq 0) { return }
    $pos = $btn.TranslatePoint((New-Object System.Windows.Point(0,0)), $container)
    
    $targetX = $pos.X
    $targetW = $btn.ActualWidth
    $animX = New-Object System.Windows.Media.Animation.DoubleAnimation -Property @{ To = $targetX; Duration = "0:0:0.25"; EasingFunction = (New-Object System.Windows.Media.Animation.QuarticEase -Property @{ EasingMode = 'EaseOut' }) }
    $animW = New-Object System.Windows.Media.Animation.DoubleAnimation -Property @{ To = $targetW; Duration = "0:0:0.25"; EasingFunction = (New-Object System.Windows.Media.Animation.QuarticEase -Property @{ EasingMode = 'EaseOut' }) }
    
    $transform.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $animX)
    $selector.BeginAnimation([System.Windows.FrameworkElement]::WidthProperty, $animW)
}

# Tab event handlers
$ui.FindName("TAB_GAMEPERF_GAMES").Add_Checked({ Set-GamePerfTabSelector $this; $global:currentGamePerfTab = "GAMES"; $ui.FindName("INP_GAMEPERF_SEARCH").Text = "Search games..."; $ui.FindName("INP_GAMEPERF_SEARCH").Foreground = "#7B8498"; Update-GamePerfView -animate $true })
$ui.FindName("TAB_GAMEPERF_LAUNCHERS").Add_Checked({ Set-GamePerfTabSelector $this; $global:currentGamePerfTab = "LAUNCHERS"; $ui.FindName("INP_GAMEPERF_SEARCH").Text = "Search launchers..."; $ui.FindName("INP_GAMEPERF_SEARCH").Foreground = "#7B8498"; Update-GamePerfView -animate $true })
$ui.FindName("TAB_GAMEPERF_SOFTWARE").Add_Checked({ Set-GamePerfTabSelector $this; $global:currentGamePerfTab = "SOFTWARE"; $ui.FindName("INP_GAMEPERF_SEARCH").Text = "Search software..."; $ui.FindName("INP_GAMEPERF_SEARCH").Foreground = "#7B8498"; Update-GamePerfView -animate $true })

# Initialize view when shown
$ui.FindName("VIEW_OTHER").Add_IsVisibleChanged({
    if ($this.IsVisible) {
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke("Background", [Action]{
            $btn = $ui.FindName("TAB_GAMEPERF_$global:currentGamePerfTab")
            if ($null -ne $btn) { Set-GamePerfTabSelector $btn }
            Update-GamePerfView -animate $true
        })
    }
})
