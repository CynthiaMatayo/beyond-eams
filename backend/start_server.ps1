# Beyond EAMS Backend Server Startup Script
Write-Host "========================================" -ForegroundColor Green
Write-Host "   Beyond EAMS Backend Server" -ForegroundColor Green  
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Change to backend directory
Set-Location -Path $PSScriptRoot

# Check Python installation
Write-Host "Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host $pythonVersion -ForegroundColor Green
} catch {
    Write-Host "ERROR: Python is not installed or not in PATH" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Django installation
Write-Host ""
Write-Host "Checking Django installation..." -ForegroundColor Yellow
try {
    python -c "import django; print('Django version:', django.VERSION)" 2>&1
    Write-Host "Django is installed" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Django is not installed" -ForegroundColor Red
    Write-Host "Please install Django: pip install django djangorestframework" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Apply migrations
Write-Host ""
Write-Host "Applying database migrations..." -ForegroundColor Yellow
try {
    python manage.py migrate
    Write-Host "Migrations applied successfully" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not apply migrations" -ForegroundColor Yellow
}

# Create admin user
Write-Host ""
Write-Host "Creating admin user admin.cynthia..." -ForegroundColor Yellow
try {
    python create_admin_user.py
    Write-Host "Admin user ready" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not create admin user" -ForegroundColor Yellow
}

# Start server
Write-Host ""
Write-Host "Starting Django development server..." -ForegroundColor Yellow
Write-Host "Server will be available at: http://127.0.0.1:8000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

python manage.py runserver 127.0.0.1:8000
