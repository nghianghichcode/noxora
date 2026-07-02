$lines = Get-Content "$PSScriptRoot\..\XAML\layout.xaml"
$depth = 0
for ($i = 560; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '<Border[\s>]' -and $line -notmatch '</Border>') { Write-Host "OPEN Border $($i+1)"; $depth++ }
    if ($line -match '</Border>') { Write-Host "CLOSE Border $($i+1)"; $depth-- }
    if ($line -match '<Grid[\s>]' -and $line -notmatch '</Grid>') { Write-Host "OPEN Grid $($i+1): $($line.Trim().Substring(0,[Math]::Min(60,$line.Trim().Length)))" }
    if ($line -match '</Grid>') { Write-Host "CLOSE Grid $($i+1)" }
}
