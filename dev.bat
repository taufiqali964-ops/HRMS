@echo off
echo ========================================
echo Starting Leave Management System
echo ========================================
echo.
echo Checking environment...
echo.

REM Check if node_modules exists
if not exist "node_modules" (
    echo node_modules not found! Installing dependencies...
    call npm install
    if errorlevel 1 (
        echo Error installing dependencies!
        pause
        exit /b 1
    )
)

REM Check if .env.local exists
if not exist ".env.local" (
    echo WARNING: .env.local not found! Copying from example...
    copy ".env.local.example" ".env.local"
    echo Please configure .env.local with your database credentials!
    pause
)

echo.
echo Starting development server...
echo The application will be available at: http://localhost:3000
echo.
echo Press Ctrl+C to stop the server
echo.

call npm run dev
