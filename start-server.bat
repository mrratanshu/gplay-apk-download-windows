@echo off
setlocal
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

if "%PORT%"=="" set PORT=5000
set PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python

if "%1"=="dev" (
    set FLASK_DEBUG=true
)

echo Starting GPlay APK Downloader on http://localhost:%PORT% ...
if exist "%SCRIPT_DIR%.venv\Scripts\python.exe" (
    "%SCRIPT_DIR%.venv\Scripts\python.exe" server.py
) else (
    python server.py
)
