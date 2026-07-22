@echo off
setlocal enabledelayedexpansion

echo ========================================
echo QUICK START - Leave Management System
echo ========================================
echo.

cd /d "%~dp0"

REM Check if node_modules exists
if not exist "node_modules" (
    echo Installing dependencies... This may take a few minutes.
    call npm.cmd install
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to install dependencies.
        echo Please check your internet connection and try again.
        pause
        exit /b 1
    )
    echo.
)

REM Ensure .env.local exists
if not exist ".env.local" (
    copy ".env.local.example" ".env.local" >nul
)

REM Clean build
if exist ".next" (
    rmdir /s /q ".next" >nul 2>&1
)

echo ========================================
echo Starting Server...
echo ========================================
echo.
echo If you see "Ready" below, open: http://localhost:3000
echo.
echo NOTE: If you see database errors, you need to:
echo   1. Start MySQL service
echo   2. Create database: CREATE DATABASE ali_hr_leave;
echo   3. Import schema: mysql -u root -p ali_hr_leave ^< database\schema.sql
echo.
echo Press Ctrl+C to stop the server
echo.

timeout /t 3 /nobreak >nul

REM Start the server
call npm.cmd run dev
