@echo off
echo ========================================
echo AUTOMATED SETUP - Leave Management System
echo ========================================
echo.

cd /d "%~dp0"

echo [1/5] Installing dependencies...
call npm install --silent
if errorlevel 1 (
    echo ERROR: npm install failed
    pause
    exit /b 1
)
echo Done.
echo.

echo [2/5] Checking .env.local...
if not exist ".env.local" (
    copy ".env.local.example" ".env.local" >nul
    echo Created .env.local from template
)
echo Done.
echo.

echo [3/5] Setting up database (if MySQL is running)...
echo.
echo Creating database ali_hr_leave...
mysql -u root --password= -e "CREATE DATABASE IF NOT EXISTS ali_hr_leave;" 2>nul
if errorlevel 1 (
    echo Note: Could not create database automatically.
    echo This is OK if MySQL requires a password or is not running.
    echo You can create it manually later.
) else (
    echo Database created successfully!
    echo.
    echo Importing schema...
    mysql -u root --password= ali_hr_leave < database\schema.sql 2>nul
    if errorlevel 1 (
        echo Note: Could not import schema automatically.
        echo You can import it manually: mysql -u root -p ali_hr_leave ^< database\schema.sql
    ) else (
        echo Schema imported successfully!
    )
)
echo.

echo [4/5] Clearing build cache...
if exist ".next" (
    rmdir /s /q ".next" >nul 2>&1
)
echo Done.
echo.

echo [5/5] Starting development server...
echo.
echo Server will start on http://localhost:3000
echo Press Ctrl+C to stop
echo.
timeout /t 2 /nobreak >nul

start http://localhost:3000

npm run dev
