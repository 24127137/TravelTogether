@echo off
REM Script khởi động backend cho thiết bị Android thật
REM Chạy với: run_server.bat

echo === Khởi động Backend Travel Together ===
echo Backend sẽ lắng nghe trên 0.0.0.0:8000 (cho phép thiết bị Android kết nối)
echo.

REM Kích hoạt môi trường ảo nếu có
if exist venv\Scripts\activate.bat (
    echo Kích hoạt môi trường ảo...
    call venv\Scripts\activate.bat
)

REM Chạy uvicorn với host 0.0.0.0
echo Khởi động server...
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

