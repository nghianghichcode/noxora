# updater.ps1
# Update script for Platinum+ Optimizer (Portable & Setup)
[CmdletBinding()]
param(
    [string]$AppPath = $PSScriptRoot,
    [switch]$Force
)

# Force secure HTTPS connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$baseUrl = "https://platinum.optimizer.workers.dev/program"
$versionUrl = "$baseUrl/version.json"

Write-Host "=== Platinum+ Auto-Updater ===" -ForegroundColor Cyan
Write-Host "Checking for updates from: $baseUrl"

# Detect mode
$isPortable = $false
$isSetup = $false

if (Test-Path "$AppPath\portable_config.json") {
    $isPortable = $true
    Write-Host "Mode: Portable"
} elseif (Test-Path "$AppPath\install_config.json") {
    $isSetup = $true
    Write-Host "Mode: Installed (Setup)"
} else {
    Write-Host "Warning: No configuration file found in $AppPath" -ForegroundColor Yellow
    Write-Host "Assuming Portable mode by default."
    $isPortable = $true
}

$manifestUrl = if ($isPortable) { "$baseUrl/manifest-portable.json" } else { "$baseUrl/manifest-setup.json" }

# SHA-256 function
function Get-FileSHA256($Path) {
    if (-not (Test-Path $Path -PathType Leaf)) { return $null }
    try {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLower()
    } catch { return $null }
}

# 1. Download version.json
try {
    $remoteVersion = Invoke-RestMethod -Uri $versionUrl -UseBasicParsing
    Write-Host "Latest version on server: $($remoteVersion.version)"
} catch {
    Write-Error "Failed to connect to the server to check for updates: $_"
    exit 1
}

# Read local version (if available) for quick check
$localVersionFile = "$AppPath\update_info.json"
if (-not $Force -and (Test-Path $localVersionFile)) {
    $localVersion = Get-Content $localVersionFile -Raw | ConvertFrom-Json
    if ($localVersion.version -eq $remoteVersion.version) {
        Write-Host "The program is already up to date with version $($remoteVersion.version)!" -ForegroundColor Green
        exit 0
    }
}

# 2. Download manifest
Write-Host "Downloading file manifest..."
try {
    $manifest = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing
} catch {
    Write-Error "Failed to download the manifest: $_"
    exit 1
}

# 3. Analyze files to update
$filesToDownload = @()
# Determine subfolder based on mode
$modeFolder = if ($isPortable) { "Portable" } else { "Setup" }

Write-Host "Comparing file hashes..."
$i = 0
$totalFiles = $manifest.files.Count
foreach ($file in $manifest.files) {
    $i++
    Write-Progress -Activity "Analyzing files" -Status "$($file.path)" -PercentComplete (($i / $totalFiles) * 100)
    
    $localFilePath = "$AppPath\$($file.path)"
    $localHash = Get-FileSHA256 -Path $localFilePath
    
    if ($localHash -ne $file.hash.ToLower()) {
        $filesToDownload += $file
    }
}
Write-Progress -Activity "Analyzing files" -Completed

if ($filesToDownload.Count -eq 0) {
    Write-Host "All files are already up to date." -ForegroundColor Green
    # Update version info just to be sure
    $remoteVersion | ConvertTo-Json | Out-File $localVersionFile -Encoding UTF8
    exit 0
}

Write-Host "Found $($filesToDownload.Count) files to update." -ForegroundColor Yellow

# 4. Close application if in use
$appProcesses = Get-WmiObject Win32_Process | Where-Object { 
    $_.Name -match 'powershell' -and ($_.CommandLine -match 'run.ps1' -or $_.CommandLine -match 'interfaccia_grafica.ps1') 
}

if ($appProcesses) {
    Write-Host "Closing application..." -ForegroundColor Cyan
    foreach ($p in $appProcesses) {
        try {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    Start-Sleep -Seconds 2
}

# 5. Download and Replace
$downloaded = 0
$failed = 0

foreach ($file in $filesToDownload) {
    $localFilePath = "$AppPath\$($file.path)"
    # Build download URL: baseUrl/files/{mode}/{relativePath}
    $fileUrl = "$baseUrl/files/$modeFolder/$($file.path)"
    
    # Create directory if it doesn't exist
    $dir = Split-Path $localFilePath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    $success = $false
    $retryCount = 0
    $maxRetries = 3
    
    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            $pct = ($downloaded / $filesToDownload.Count) * 100
            Write-Progress -Activity "Downloading files" -Status "$($file.path)" -PercentComplete $pct
            
            # Download file
            Invoke-WebRequest -Uri $fileUrl -OutFile $localFilePath -UseBasicParsing -ErrorAction Stop
            
            # Verify hash
            $newHash = Get-FileSHA256 -Path $localFilePath
            if ($newHash -eq $file.hash.ToLower()) {
                $success = $true
                $downloaded++
            } else {
                throw "Hash mismatch for $($file.path)"
            }
        } catch {
            $retryCount++
            Write-Host "Failed to download $($file.path) (Attempt $retryCount/$maxRetries): $_" -ForegroundColor Red
            if ($retryCount -lt $maxRetries) {
                $sleepTime = [math]::Pow(2, $retryCount)
                Start-Sleep -Seconds $sleepTime
            } else {
                $failed++
            }
        }
    }
}
Write-Progress -Activity "Downloading files" -Completed

# 6. Results and Restart
if ($failed -eq 0) {
    Write-Host "Update completed successfully!" -ForegroundColor Green
    $remoteVersion | ConvertTo-Json | Out-File $localVersionFile -Encoding UTF8
} else {
    Write-Host "Update completed with $failed errors." -ForegroundColor Yellow
}

Write-Host "Restarting application..."
if (Test-Path "$AppPath\run.ps1") {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$AppPath\run.ps1`"" -WorkingDirectory $AppPath
} elseif (Test-Path "$AppPath\interfaccia_grafica.ps1") {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$AppPath\interfaccia_grafica.ps1`"" -WorkingDirectory $AppPath
}

exit 0
