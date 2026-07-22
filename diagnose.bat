@echo off
setlocal enabledelayedexpansion

echo ========================================
echo System Diagnostics
echo ========================================
echo.

REM Check Node.js
echo [1/6] Checking Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Node.js not found! Install from https://nodejs.org/
    set /a ERRORS+=1
) else (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VER=%%i
    echo [OK] Node.js !NODE_VER! installed
)
echo.

REM Check npm
echo [2/6] Checking npm...
npm --version >nul 2>&1
if errorlevel 1 (
    echo [FAIL] npm not found!
    set /a ERRORS+=1
) else (
    for /f "tokens=*" %%i in ('npm --version') do set NPM_VER=%%i
    echo [OK] npm !NPM_VER! installed
)
echo.

REM Check MySQL
echo [3/6] Checking MySQL...
where mysql >nul 2>&1
if errorlevel 1 (
    echo [WARN] MySQL not in PATH
    echo       This is OK if MySQL is installed and running
    echo       You can access it through MySQL Workbench or other tools
) else (
    for /f "tokens=*" %%i in ('mysql --version 2^>nul') do set MYSQL_VER=%%i
    echo [OK] MySQL found: !MYSQL_VER!
)
echo.

REM Check .env.local
echo [4/6] Checking .env.local...
if not exist ".env.local" (
    echo [FAIL] .env.local not found!
    echo       Copy .env.local.example to .env.local and configure it
    set /a ERRORS+=1
) else (
    echo [OK] .env.local exists
    echo.
    echo Current configuration:
    type .env.local | findstr /B /C:"DB_" /C:"JWT_SECRET"
    echo.
    findstr /C:"DB_PASSWORD=" .env.local | findstr /C:"DB_PASSWORD=$" >nul
    if not errorlevel 1 (
        echo [WARN] DB_PASSWORD appears to be empty!
        echo        Set your MySQL password in .env.local
        echo        If MySQL has no password, this is fine for local dev
    )
)
echo.

REM Check node_modules
echo [5/6] Checking dependencies...
if not exist "node_modules" (
    echo [WARN] node_modules not found
    echo        Run: npm install
) else (
    echo [OK] node_modules exists
)
echo.

REM Check database schema file
echo [6/6] Checking database schema...
if not exist "database\schema.sql" (
    echo [FAIL] database\schema.sql not found!
    set /a ERRORS+=1
) else (
    echo [OK] database\schema.sql exists
    for %%A in ("database\schema.sql") do set SIZE=%%~zA
    echo       File size: !SIZE! bytes
)
echo.

echo ========================================
echo Diagnostic Summary
echo ========================================
echo.

if defined ERRORS (
    echo [FAIL] Found !ERRORS! critical issue(s)
    echo.
    echo Fix the issues above before starting the server.
) else (
    echo [OK] All critical checks passed!
    echo.
    echo Next steps:
    echo   1. Make sure MySQL server is running
    echo   2. Create database: CREATE DATABASE ali_hr_leave;
    echo   3. Import schema: mysql -u root -p ali_hr_leave ^< database\schema.sql
    echo   4. Set DB_PASSWORD in .env.local (if MySQL has a password)
    echo   5. Run: npm run dev (or start-dev.bat)
)
echo.

pause
