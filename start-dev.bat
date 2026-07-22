@echo off
echo ========================================
echo Starting Development Server
echo ========================================
echo.

cd /d "%~dp0"

REM Check if .env.local exists
if not exist ".env.local" (
    echo ERROR: .env.local file not found!
    echo Creating from template...
    copy ".env.local.example" ".env.local"
    echo.
    echo IMPORTANT: Please edit .env.local and set your MySQL password!
    echo Then run this script again.
    echo.
    pause
    exit /b 1
)

REM Check if node_modules exists
if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies!
        pause
        exit /b 1
    )
    echo.
)

echo Checking database configuration...
echo.
echo Make sure MySQL is running and database is set up:
echo   1. MySQL server is running
echo   2. Database 'ali_hr_leave' exists
echo   3. Schema is imported (database/schema.sql)
echo   4. .env.local has correct credentials
echo.
echo Press Ctrl+C now if you need to set these up first.
echo Otherwise, the server will start in 5 seconds...
timeout /t 5 /nobreak

echo.
echo ========================================
echo Starting Next.js Development Server
echo ========================================
echo.
echo Server will be available at: http://localhost:3000
echo Press Ctrl+C to stop the server
echo.

npm run dev
