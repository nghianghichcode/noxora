# HashGenerator.ps1
# Modulo helper per la generazione degli hash SHA-256 e dei manifest

function Get-FileHashSHA256 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path -PathType Leaf)) {
        return $null
    }
    
    try {
        $hashObj = Get-FileHash -Path $Path -Algorithm SHA256 -ErrorAction Stop
        return $hashObj.Hash.ToLower()
    }
    catch {
        Write-Warning "Impossibile calcolare hash per '$Path': $_"
        return $null
    }
}

function Get-DirectoryManifest {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [string[]]$ExcludePatterns = @(
            "config/state.json",
            ".git",
            ".agents",
            "scratch",
            "log",
            "*.tmp",
            "*.bak"
        )
    )
    
    if (-not (Test-Path $Path -PathType Container)) {
        throw "La directory specificata non esiste: $Path"
    }
    
    $manifest = @()
    $basePath = (Resolve-Path $Path).Path
    
    # Raccoglie tutti i file ricorsivamente
    $files = Get-ChildItem -Path $basePath -Recurse -File
    
    foreach ($file in $files) {
        # Percorso relativo con / (normalizzato per il web)
        $relPath = $file.FullName.Substring($basePath.Length).TrimStart('\', '/')
        $relPathNormalized = $relPath -replace '\\', '/'
        
        # Controlla se il file deve essere escluso
        $isExcluded = $false
        foreach ($pattern in $ExcludePatterns) {
            # Converti il pattern per supportare sia / che \
            $regexPattern = [regex]::Escape($pattern) -replace '\\/', '(/|\\)'
            if ($relPathNormalized -match $regexPattern) {
                $isExcluded = $true
                break
            }
        }
        
        if ($isExcluded) {
            continue
        }
        
        $hash = Get-FileHashSHA256 -Path $file.FullName
        if ($hash) {
            $manifest += [ordered]@{
                path = $relPathNormalized
                hash = $hash
                size = $file.Length
            }
        }
    }
    
    return $manifest
}
