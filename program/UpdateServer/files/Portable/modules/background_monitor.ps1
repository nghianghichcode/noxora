# Multi-threading Background Engine (Zero UI Lag)
$global:BgHash = [hashtable]::Synchronized(@{
    GpuUse = 0; NetRx = 0; NetTx = 0; NetName = $null; IsRunning = $true; CpuClock = 0;
    NvidiaVramUsed = 0; NvidiaVramTotal = 0; NvidiaTemp = 0; TopProcs = $null; IsNvidia = $false;
    CpuTemp = 0; GpuTemp = 0 # AGGIUNTI: Se mancano, l'UI mostra i trattini "--"
})

$global:BgRs = [runspacefactory]::CreateRunspace()
$global:BgRs.Open()
$global:BgRs.SessionStateProxy.SetVariable("bgHash", $global:BgHash)
$global:BgRs.SessionStateProxy.SetVariable("scriptRoot", $PSScriptRoot) # Passiamo il percorso per le DLL

$global:BgPs = [powershell]::Create().AddScript({
    # --- CARICAMENTO DLL DENTRO IL RUNSPACE ---
    $libreDll = Join-Path $scriptRoot "libs\LibreHardwareMonitor\LibreHardwareMonitorLib.dll"
    $openDll  = Join-Path $scriptRoot "libs\OpenHardwareMonitor\OpenHardwareMonitorLib.dll"
    if (Test-Path $libreDll) { try { Add-Type -Path $libreDll } catch {} }
    if (Test-Path $openDll)  { try { Add-Type -Path $openDll } catch {} }

    $cpuCim = Get-CimInstance Win32_Processor -Property MaxClockSpeed -ErrorAction SilentlyContinue | Select-Object -First 1
    $maxClock = if ($cpuCim) { $cpuCim.MaxClockSpeed } else { 0 }
    
    # FIX: RIMOSSO SPAZIO FINALE nel percorso di nvidia-smi
    $nvidiaSmi = "C:\Windows\System32\nvidia-smi.exe" 
    $hasNvidia = Test-Path $nvidiaSmi

    # Inizializzazione Librerie
    $libreComp = $null; $openComp = $null
    try { 
        $libreComp = New-Object LibreHardwareMonitor.Hardware.Computer
        $libreComp.IsCpuEnabled = $true; $libreComp.IsGpuEnabled = $true
        $libreComp.Open() 
    } catch {}
    
    try { 
        $openComp = New-Object OpenHardwareMonitor.Hardware.Computer
        $openComp.CPUEnabled = $true; $openComp.GPUEnabled = $true # FIX: Open usa CPUEnabled
        $openComp.Open() 
    } catch {}

    # Funzione Fallback (Libre -> Open)
    function Get-SafeSensorValue {
        param([string]$SenType, [string]$SenName = "")
        $val = $null
        $comps = @($libreComp, $openComp)
        foreach ($comp in $comps) {
            if ($comp) {
                try {
                    $comp.Hardware | ForEach-Object { $_.Update() }
                    foreach ($hw in $comp.Hardware) {
                        foreach ($s in $hw.Sensors) {
                            if ($s.SensorType.ToString() -eq $SenType) {
                                if ($SenName -eq "" -or $s.Name -like "*$SenName*") {
                                    # Controlla che il valore esista e sia > 0 (gestisce i null di Libre)
                                    if ($s.Value -and $s.Value -gt 0) { 
                                        $val = [double]$s.Value
                                        break 
                                    }
                                }
                            }
                        }
                        if ($val) { break }
                    }
                } catch {}
            }
            if ($val) { break } 
        }
        return $val
    }

    while($bgHash.IsRunning) {
        try {
            # FIX: RIMOSSO SPAZIO FINALE nel contatore
            $perfCounter = Get-Counter "\Processor Information(_Total)\% Processor Performance" -ErrorAction SilentlyContinue
            if ($perfCounter -and $maxClock -gt 0) {
                $bgHash.CpuClock = $maxClock * ($perfCounter.CounterSamples[0].CookedValue / 100.0)
            } else {
                $m = Get-CimInstance Win32_Processor -Property CurrentClockSpeed -ErrorAction SilentlyContinue | Select-Object -First 1
                # FIX: RIMOSSO SPAZIO in CurrentClockSpeed
                if ($m -and $m.CurrentClockSpeed) { $bgHash.CpuClock = $m.CurrentClockSpeed }
            }
        } catch {}
        
        try {
            # FIX: RIMOSSO SPAZIO in $procs (era $proc s)
            $procs = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU, Id | ConvertTo-Json -Compress
            $bgHash.TopProcs = $procs
        } catch {}

        try {
            if ($bgHash.IsNvidia -and $hasNvidia) {
                $smiOut = & $nvidiaSmi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits -ErrorAction SilentlyContinue
                if ($smiOut) {
                    $parts = $smiOut -split ','
                    if ($parts.Count -ge 4) {
                        $bgHash.GpuUse = [double]$parts[0].Trim()
                        $bgHash.NvidiaVramUsed = [double]$parts[1].Trim()
                        $bgHash.NvidiaVramTotal = [double]$parts[2].Trim()
                        $bgHash.NvidiaTemp = [double]$parts[3].Trim()
                    }
                }
            } else {
                $gu = 0
                # FIX: RIMOSSO SPAZIO FINALE nel contatore GPU
                $gpus = Get-Counter "\GPU Engine(*engtype_3D)\Utilization Percentage" -ErrorAction SilentlyContinue
                if ($gpus) { foreach ($v in $gpus.CounterSamples) { $gu += $v.CookedValue } }
                if ($gu -gt 100) { $gu = 100 }
                # FIX: RIMOSSO SPAZIO in $bgHash (era $bg Hash)
                $bgHash.GpuUse = $gu
            }
        } catch {}

        # --- LETTURE TEMPERATURE (Evita i trattini) ---
        try {
            $cpuT = Get-SafeSensorValue -SenType 'Temperature' -SenName 'Package'
            if (-not $cpuT -or $cpuT -eq 0) { $cpuT = Get-SafeSensorValue -SenType 'Temperature' -SenName 'Core' }
            $bgHash.CpuTemp = if ($cpuT) { $cpuT } else { 0 }

            if (-not $bgHash.IsNvidia -or $bgHash.NvidiaTemp -eq 0) {
                $gpuT = Get-SafeSensorValue -SenType 'Temperature' -SenName 'GPU'
                $bgHash.GpuTemp = if ($gpuT) { $gpuT } else { 0 }
            } else {
                $bgHash.GpuTemp = $bgHash.NvidiaTemp
            }
        } catch {}

        if ($bgHash.NetName) {
            try {
                $ns = Get-NetAdapterStatistics -Name $bgHash.NetName -ErrorAction SilentlyContinue
                if ($ns) { $bgHash.NetRx = $ns.ReceivedBytes; $bgHash.NetTx = $ns.SentBytes }
            } catch {}
        }
        Start-Sleep -Seconds 2
    }
})

$global:BgPs.Runspace = $global:BgRs
$global:BgJob = $global:BgPs.BeginInvoke()