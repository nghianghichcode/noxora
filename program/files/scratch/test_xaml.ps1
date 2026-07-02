Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
$xml = Get-Content "$PSScriptRoot\..\XAML\layout.xaml" -Raw -Encoding UTF8
$xml = $xml -replace '\$W', '1280' -replace '\$H', '800'
try {
    [void][Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$xml))
    Write-Host 'XAML OK'
    exit 0
} catch {
    Write-Host "XAML ERROR: $($_.Exception.Message)"
    exit 1
}
