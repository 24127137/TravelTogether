@echo off
TITLE Travel App Backend Server
COLOR 0A

ECHO ======================================================
ECHO        DANG KHOI DONG SERVER BACKEND...`
ECHO ======================================================
ECHO.

:: Lệnh chạy server (giống hệt lệnh bạn hay gõ)
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000

:: Giữ màn hình không bị tắt nếu có lỗi
PAUSE