@echo off
echo ========================================
echo    Beyond EAMS Backend Server Startup
echo ========================================
echo.

cd /d "%~dp0"

echo Starting Django development server...
echo Server will be available at: http://127.0.0.1:8000
echo.
echo Press Ctrl+C to stop the server
echo ========================================

python manage.py runserver 127.0.0.1:8000

pause
