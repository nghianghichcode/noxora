# BuildManifest.ps1
# Script per generare la cartella UpdateServer e i relativi manifest

param (
    [string]$Version
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$updateServerDir = (Resolve-Path "$scriptDir\..").Path
$programmaDir = (Resolve-Path "$scriptDir\..\..\..\programma").Path

# Modulo helper
. "$scriptDir\HashGenerator.ps1"

$baseUrl = "https://platinum.optimizer.workers.dev/program"
$versionFile = "$updateServerDir\version.json"

# 1. Gestione Versione
if (-not $Version) {
    if (Test-Path $versionFile) {
        $oldVersionJson = Get-Content $versionFile -Raw | ConvertFrom-Json
        $oldVersion = $oldVersionJson.version
        
        # Auto-incremento patch (es. 1.0.0 -> 1.0.1)
        if ($oldVersion -match "^(\d+)\.(\d+)\.(\d+)$") {
            $major = $matches[1]
            $minor = $matches[2]
            $patch = [int]$matches[3] + 1
            $Version = "$major.$minor.$patch"
        } else {
            $Version = "1.0.0"
        }
    } else {
        $Version = "1.0.0"
    }
}

Write-Host "Generazione Build versione $Version..." -ForegroundColor Cyan
$buildDate = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")

# 2. Pulizia cartelle Files
$filesPortableDir = "$updateServerDir\files\Portable"
$filesSetupDir = "$updateServerDir\files\Setup"

foreach ($dir in @($filesPortableDir, $filesSetupDir)) {
    if (Test-Path $dir) {
        Write-Host "Pulizia cartella $dir..."
        Remove-Item "$dir\*" -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# 3. Copia File Sorgenti
Write-Host "Copia file da $programmaDir..."
# Esclusioni dalla copia
$excludeForCopy = @("config", ".git", ".agents", "scratch", "log")

Get-ChildItem -Path $programmaDir | Where-Object { $_.Name -notin $excludeForCopy } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $filesPortableDir -Recurse -Force
    Copy-Item -Path $_.FullName -Destination $filesSetupDir -Recurse -Force
}

# Ricreiamo la cartella config vuota con il solo state.json per evitare errori, ma verrà ignorato dai manifest
New-Item -ItemType Directory -Path "$filesPortableDir\config" -Force | Out-Null
New-Item -ItemType Directory -Path "$filesSetupDir\config" -Force | Out-Null

# 4. Generazione Manifest
Write-Host "Calcolo Hash e Generazione Manifest Portable..."
$portableManifestObj = Get-DirectoryManifest -Path $filesPortableDir
$portableManifest = @{
    version = $Version
    buildDate = $buildDate
    baseUrl = "$baseUrl/files/Portable/"
    files = $portableManifestObj
}
$portableManifest | ConvertTo-Json -Depth 5 | Out-File "$updateServerDir\manifest-portable.json" -Encoding UTF8

Write-Host "Calcolo Hash e Generazione Manifest Setup..."
$setupManifestObj = Get-DirectoryManifest -Path $filesSetupDir
$setupManifest = @{
    version = $Version
    buildDate = $buildDate
    baseUrl = "$baseUrl/files/Setup/"
    files = $setupManifestObj
}
$setupManifest | ConvertTo-Json -Depth 5 | Out-File "$updateServerDir\manifest-setup.json" -Encoding UTF8

# 5. Generazione version.json
Write-Host "Salvataggio version.json..."
$versionInfo = @{
    version = $Version
    buildDate = $buildDate
    minPSVersion = "5.1"
}
$versionInfo | ConvertTo-Json -Depth 5 | Out-File $versionFile -Encoding UTF8

Write-Host ""
Write-Host "=== Build Completata con Successo! ===" -ForegroundColor Green
Write-Host "Versione: $Version"
Write-Host "File Portable: $($portableManifestObj.Count)"
Write-Host "File Setup:    $($setupManifestObj.Count)"
Write-Host "La cartella UpdateServer (o /program/) è pronta per il caricamento."
