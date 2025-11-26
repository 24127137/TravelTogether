# Script khởi động backend cho thiết bị Android thật
# Chạy với: .\run_server.ps1

Write-Host "=== Khởi động Backend Travel Together ===" -ForegroundColor Green
Write-Host "Backend sẽ lắng nghe trên 0.0.0.0:8000 (cho phép thiết bị Android kết nối)" -ForegroundColor Yellow
Write-Host ""

# Kích hoạt môi trường ảo nếu có
if (Test-Path "venv\Scripts\Activate.ps1") {
    Write-Host "Kích hoạt môi trường ảo..." -ForegroundColor Cyan
    .\venv\Scripts\Activate.ps1
}

# Chạy uvicorn với host 0.0.0.0
Write-Host "Khởi động server..." -ForegroundColor Cyan
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

