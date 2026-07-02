Add-Type -AssemblyName System.Drawing
$pngPath = "c:\Users\Admin\platinum\setup\ico\platinum.png"
$icoPath = "c:\Users\Admin\platinum\setup\ico\platinum.ico"

$img = [System.Drawing.Image]::FromFile($pngPath)
$bmp = New-Object System.Drawing.Bitmap($img)
$hicon = $bmp.GetHicon()
$ico = [System.Drawing.Icon]::FromHandle($hicon)
$fs = New-Object System.IO.FileStream($icoPath, [System.IO.FileMode]::Create)
$ico.Save($fs)
$fs.Close()
$img.Dispose()
$bmp.Dispose()
Write-Host "Converted successfully to $icoPath"
