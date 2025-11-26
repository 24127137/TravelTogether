@echo off
REM Script to start the backend for a real Android device
REM Run with: run_server.bat

echo === Starting Travel Together Backend ===
echo The Backend will listen on 0.0.0.0:8000 (allowing Android device connection)
echo.

REM Activate virtual environment if available
if exist venv\Scripts\activate.bat (
    echo Activating virtual environment...
    call venv\Scripts\activate.bat
)

REM Start uvicorn with host 0.0.0.0
echo Starting server...
uvicorn main:app --host 0.0.0.0 --port 8000 --reload