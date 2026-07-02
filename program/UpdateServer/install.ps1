# install.ps1
# Online Installation Script (Bootstrap) for Platinum+ Optimizer
[CmdletBinding()]
param(
    [switch]$Portable
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$baseUrl = "https://platinum.optimizer.workers.dev/program"
$updaterUrl = "$baseUrl/updater.ps1"

Write-Host "=== Platinum+ Optimizer Installation ===" -ForegroundColor Cyan

$tempDir = Join-Path $env:TEMP "PlatinumSetup_$([Guid]::NewGuid().ToString().Substring(0,8))"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

$updaterPath = Join-Path $tempDir "updater.ps1"

try {
    Write-Host "Downloading installation system..."
    Invoke-WebRequest -Uri $updaterUrl -OutFile $updaterPath -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Error "Failed to download setup files: $_"
    exit 1
}

$destFolder = ""
if ($Portable) {
    Write-Host "Select the folder for the Portable installation..."
    
    Add-Type -AssemblyName System.Windows.Forms
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select the folder for Platinum+ Portable"
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $destFolder = Join-Path $folderBrowser.SelectedPath "Platinum+_Portable"
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
        
        # Create a dummy portable config to trigger the updater
        @{ InstallType = "Portable" } | ConvertTo-Json | Out-File (Join-Path $destFolder "portable_config.json") -Encoding UTF8
    } else {
        Write-Host "Installation cancelled."
        exit 0
    }
} else {
    $destFolder = Join-Path $env:ProgramFiles "Platinum+ Optimizer"
    Write-Host "Installing to $destFolder..."
    if (-not (Test-Path $destFolder)) {
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
    }
    # Create setup config
    @{ InstallType = "Normal" } | ConvertTo-Json | Out-File (Join-Path $destFolder "install_config.json") -Encoding UTF8
}

# Copy updater to the destination
Copy-Item -Path $updaterPath -Destination $destFolder -Force

# Run the updater in force mode to download all files
Write-Host "Starting download of application files..."
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($destFolder)\updater.ps1`" -Force" -WorkingDirectory $destFolder -Wait

Write-Host "Installation completed!" -ForegroundColor Green
Write-Host "Starting Platinum+ Optimizer..."
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($destFolder)\run.ps1`"" -WorkingDirectory $destFolder

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
exit 0
