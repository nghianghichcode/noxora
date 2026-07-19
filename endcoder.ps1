# Đọc toàn bộ code từ file i.ps1 gốc
$OriginalScript = Get-Content -Path ".\i.ps1" -Raw

# Chuyển đổi mã nguồn thành các byte, sau đó mã hóa sang chuỗi Base64
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($OriginalScript)
$Base64String = [System.Convert]::ToBase64String($Bytes)

# Tạo ra đoạn mã mồi (Payload) để tự giải mã khi chạy
$Payload = "Invoke-Expression ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('$Base64String')))"

# Lưu đè kết quả đã mã hóa ngược lại vào file i.ps1 (hoặc tạo file mới để test)
Set-Content -Path ".\i_encrypted.ps1" -Value $Payload

Write-Host "MÃ HÓA THÀNH CÔNG! Hãy xem file i_encrypted.ps1" -ForegroundColor Green