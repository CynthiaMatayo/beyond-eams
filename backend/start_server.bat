@echo off
echo Starting Django Backend Server...
echo.

cd /d "%~dp0"

echo Checking if virtual environment exists...
if exist venv (
    echo Activating virtual environment...
    call venv\Scripts\activate
) else (
    echo No virtual environment found, using system Python...
)

echo.
echo Starting Django development server...
python manage.py runserver 127.0.0.1:8000

echo.
echo Server stopped.
pause
