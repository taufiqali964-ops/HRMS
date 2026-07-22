@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Leave Management System - Build Test
echo ========================================
echo.

REM Change to project directory
cd /d "%~dp0"

echo Current directory: %CD%
echo.

REM Check Node.js
echo Checking Node.js installation...
node --version 2>nul
if errorlevel 1 (
    echo ERROR: Node.js is not installed or not in PATH!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)
echo Node.js: OK
echo.

REM Check npm
echo Checking npm installation...
npm --version 2>nul
if errorlevel 1 (
    echo ERROR: npm is not available!
    pause
    exit /b 1
)
echo npm: OK
echo.

REM Check node_modules
if not exist "node_modules" (
    echo node_modules not found!
    echo Installing dependencies...
    call npm install
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies!
        pause
        exit /b 1
    )
) else (
    echo node_modules: OK
)
echo.

REM Check .env.local
if not exist ".env.local" (
    echo WARNING: .env.local not found!
    echo Creating from .env.local.example...
    copy ".env.local.example" ".env.local" >nul
    echo Please edit .env.local with your database credentials!
) else (
    echo .env.local: OK
)
echo.

REM Clean previous build
if exist ".next" (
    echo Cleaning previous build...
    rmdir /s /q ".next" 2>nul
)
echo.

REM Run build
echo ========================================
echo Running build...
echo ========================================
echo.

call npm run build

if errorlevel 1 (
    echo.
    echo ========================================
    echo BUILD FAILED!
    echo ========================================
    echo Please check the error messages above.
    echo.
    pause
    exit /b 1
) else (
    echo.
    echo ========================================
    echo BUILD SUCCESSFUL!
    echo ========================================
    echo.
    echo The application is ready to run.
    echo To start the production server: npm start
    echo To start the development server: npm run dev
    echo.
)

pause
