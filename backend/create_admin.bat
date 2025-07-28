@echo off
echo Creating admin user admin.cynthia...
echo.

cd /d "%~dp0"

python create_admin_user.py

echo.
echo Press any key to continue...
pause >nul
