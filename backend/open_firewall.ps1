# Script mở firewall cho port 8000 (CẦN QUYỀN ADMIN)
# Click phải PowerShell -> Run as Administrator, sau đó chạy: .\open_firewall.ps1

Write-Host "=== Mở Firewall cho Backend (Port 8000) ===" -ForegroundColor Green

try {
    # Tạo rule cho TCP port 8000 inbound
    New-NetFirewallRule -DisplayName "Travel Together Backend (Port 8000)" `
        -Direction Inbound `
        -LocalPort 8000 `
        -Protocol TCP `
        -Action Allow `
        -ErrorAction Stop

    Write-Host "✓ Đã tạo firewall rule cho port 8000!" -ForegroundColor Green
    Write-Host "Thiết bị Android giờ có thể kết nối tới backend." -ForegroundColor Cyan
} catch {
    Write-Host "✗ Lỗi: Không thể tạo firewall rule (cần quyền Administrator)" -ForegroundColor Red
    Write-Host "Hãy chạy PowerShell với quyền Administrator!" -ForegroundColor Yellow
}

pause

