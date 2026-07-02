function Save-TweakState {
    $configDir = "$PSScriptRoot\..\config"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir | Out-Null
    }
    
    $configPath = "$configDir\state.json"
    
    # Helper: recursively convert hashtables (including nested ones) to string-keyed ordered dicts
    function ConvertTo-StringKeys($obj) {
        if ($null -eq $obj) { return $obj }
        if ($obj -is [System.Collections.IDictionary]) {
            $d = [ordered]@{}
            foreach ($k in $obj.Keys) {
                $d["$k"] = ConvertTo-StringKeys $obj[$k]
            }
            return $d
        }
        elseif ($obj -is [System.Collections.IEnumerable] -and $obj -isnot [string]) {
            $arr = @()
            foreach ($item in $obj) {
                $arr += ConvertTo-StringKeys $item
            }
            return $arr
        }
        else {
            return $obj
        }
    }

    $state = [ordered]@{
        System  = ConvertTo-StringKeys $global:appliedTweaks
        CPU     = ConvertTo-StringKeys $global:appliedCpuTweaks
        GPU     = ConvertTo-StringKeys $global:appliedGpuTweaks
        RAM     = ConvertTo-StringKeys $global:appliedRamTweaks
        Disk    = ConvertTo-StringKeys $global:appliedDiskTweaks
        Network = ConvertTo-StringKeys $global:appliedNetTweaks
        Input   = ConvertTo-StringKeys $global:appliedInputTweaks
    }

    $state | ConvertTo-Json -Depth 4 | Out-File -FilePath $configPath -Encoding UTF8 -Force
}

function Test-TweakStateAltered($state) {
    if ($null -eq $state) { return $true }
    
    # Expected top-level keys
    $expectedKeys = @('System', 'CPU', 'GPU', 'RAM', 'Disk', 'Network', 'Input')
    
    # Check if there are any unexpected top-level keys
    foreach ($prop in $state.psobject.properties) {
        if ($expectedKeys -notcontains $prop.Name) {
            return $true
        }
    }
    
    # Check each section
    foreach ($key in $expectedKeys) {
        $section = $state.$key
        if ($null -eq $section) { continue }
        
        foreach ($prop in $section.psobject.properties) {
            $val = $prop.Value
            if ($null -eq $val) { return $true }
            
            # If the value is a nested object (like for CPU/GPU)
            if ($val -is [System.Management.Automation.PSCustomObject]) {
                # Only CPU and GPU can have nested objects
                if ($key -ne 'CPU' -and $key -ne 'GPU') { return $true }
                
                foreach ($subProp in $val.psobject.properties) {
                    $subVal = $subProp.Value
                    if ($null -eq $subVal) { return $true }
                    if ($subVal -isnot [bool] -and $subVal -isnot [int] -and $subVal -isnot [string]) { return $true }
                    # Make sure it can be evaluated as a boolean
                    if ($subVal -is [bool] -or $subVal.ToString().ToLower() -match '^(true|false)$') {
                        # ok
                    } else {
                        return $true
                    }
                }
            } else {
                # Must be a boolean value (or string representation of it)
                if ($val -is [bool] -or $val.ToString().ToLower() -match '^(true|false)$') {
                    # ok
                } else {
                    return $true
                }
            }
        }
    }
    return $false
}

function Load-TweakStateData($state) {
    # System Tweaks
    if ($null -ne $state.System) {
        foreach ($prop in $state.System.psobject.properties) {
            $k = [int]$prop.Name
            $val = [bool]$prop.Value
            if ($val) {
                $global:appliedTweaks[$k] = $true
                $t = $ui.FindName("TGL_SYS_$k")
                if ($null -ne $t) { $t.IsChecked = $true }
            }
        }
    }
    
    # CPU Tweaks
    if ($null -ne $state.CPU) {
        foreach ($prop in $state.CPU.psobject.properties) {
            if ($prop.Value -is [System.Management.Automation.PSCustomObject]) {
                $catName = $prop.Name
                foreach ($subProp in $prop.Value.psobject.properties) {
                    $k = [int]$subProp.Name
                    $val = [bool]$subProp.Value
                    if ($null -eq $global:appliedCpuTweaks[$catName]) { $global:appliedCpuTweaks[$catName] = @{} }
                    $global:appliedCpuTweaks[$catName][$k] = $val
                }
            } else {
                $k = [int]$prop.Name
                $val = [bool]$prop.Value
                if ($null -eq $global:appliedCpuTweaks["General"]) { $global:appliedCpuTweaks["General"] = @{} }
                $global:appliedCpuTweaks["General"][$k] = $val
            }
        }
    }
    
    # GPU Tweaks
    if ($null -ne $state.GPU) {
        foreach ($prop in $state.GPU.psobject.properties) {
            if ($prop.Value -is [System.Management.Automation.PSCustomObject]) {
                $catName = $prop.Name
                foreach ($subProp in $prop.Value.psobject.properties) {
                    $k = [int]$subProp.Name
                    $val = [bool]$subProp.Value
                    if ($null -eq $global:appliedGpuTweaks[$catName]) { $global:appliedGpuTweaks[$catName] = @{} }
                    $global:appliedGpuTweaks[$catName][$k] = $val
                }
            } else {
                $k = [int]$prop.Name
                $val = [bool]$prop.Value
                if ($null -eq $global:appliedGpuTweaks["General"]) { $global:appliedGpuTweaks["General"] = @{} }
                $global:appliedGpuTweaks["General"][$k] = $val
            }
        }
    }

    # RAM Tweaks
    if ($null -ne $state.RAM) {
        foreach ($prop in $state.RAM.psobject.properties) {
            $k = [int]$prop.Name
            $val = [bool]$prop.Value
            if ($val) {
                $global:appliedRamTweaks[$k] = $true
                $t = $ui.FindName("TGL_RAM_$k")
                if ($null -ne $t) { $t.IsChecked = $true }
            }
        }
    }

    # Disk Tweaks
    if ($null -ne $state.Disk) {
        foreach ($prop in $state.Disk.psobject.properties) {
            $k = [int]$prop.Name
            $val = [bool]$prop.Value
            if ($val) {
                $global:appliedDiskTweaks[$k] = $true
                $t = $ui.FindName("TGL_DISK_$k")
                if ($null -ne $t) { $t.IsChecked = $true }
            }
        }
    }

    # Network Tweaks
    if ($null -ne $state.Network) {
        foreach ($prop in $state.Network.psobject.properties) {
            $k = [int]$prop.Name
            $val = [bool]$prop.Value
            if ($val) {
                $global:appliedNetTweaks[$k] = $true
                $t = $ui.FindName("TGL_NET_$k")
                if ($null -ne $t) { $t.IsChecked = $true }
            }
        }
    }

    # Input Tweaks
    if ($null -ne $state.Input) {
        foreach ($prop in $state.Input.psobject.properties) {
            $k = [int]$prop.Name
            $val = [bool]$prop.Value
            if ($val) {
                $global:appliedInputTweaks[$k] = $true
                $t = $ui.FindName("TGL_INPUT_$k")
                if ($null -ne $t) { $t.IsChecked = $true }
            }
        }
    }
}

function Load-TweakState {
    $configPath = "$PSScriptRoot\..\config\state.json"
    if (-not (Test-Path $configPath)) {
        return
    }
    
    # $ui is available via dot-sourcing scope (same as other modules)
    try {
        $json = Get-Content $configPath -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($json)) { return }
        
        # Verify JSON validity
        $state = $json | ConvertFrom-Json
        
        if (Test-TweakStateAltered $state) {
            # File is altered!
            $global:ModalContinueAction = {
                Load-TweakStateData $state
            }
            $global:ModalOkAction = {
                Stop-Process -Id $PID -Force
            }
            if (Get-Command Show-CustomPopup -ErrorAction SilentlyContinue) {
                Show-CustomPopup "The configuration file state.json has been altered or contains invalid sections. Please reset data using the Platinum Shell, or click Continue to load it anyway." "Program Violation" "Error" -ShowContinue
            }
            return
        }

        # Valid state, load it normally
        Load-TweakStateData $state
    } catch {
        # JSON formatting is fully corrupt
        $global:ModalContinueAction = {}
        $global:ModalOkAction = {
            Stop-Process -Id $PID -Force
        }
        if (Get-Command Show-CustomPopup -ErrorAction SilentlyContinue) {
            Show-CustomPopup "The configuration file state.json is corrupted and failed to load. Please reset data using the Platinum Shell, or click Continue to load the application." "Program Violation" "Error" -ShowContinue
        }
    }
}
