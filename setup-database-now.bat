@echo off
echo ========================================
echo DATABASE SETUP - Auto Configuration
echo ========================================
echo.

cd /d "%~dp0"

echo Attempting to set up database automatically...
echo.

REM Try with empty password first (common for local MySQL)
echo [1/3] Creating database...
mysql -u root --password= -e "CREATE DATABASE IF NOT EXISTS ali_hr_leave;" 2>nul
if errorlevel 1 (
    echo Could not create with empty password. Trying with prompt...
    mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS ali_hr_leave;"
    if errorlevel 1 (
        echo.
        echo ERROR: Could not create database.
        echo Please ensure MySQL is running and try manually:
        echo   mysql -u root -p
        echo   CREATE DATABASE ali_hr_leave;
        pause
        exit /b 1
    )
)
echo Database created successfully!
echo.

echo [2/3] Importing schema...
mysql -u root --password= ali_hr_leave < "database\schema.sql" 2>nul
if errorlevel 1 (
    mysql -u root -p ali_hr_leave < "database\schema.sql"
    if errorlevel 1 (
        echo ERROR: Could not import schema
        pause
        exit /b 1
    )
)
echo Schema imported successfully!
echo.

echo [3/3] Importing seed data (users, roles, etc)...
mysql -u root --password= ali_hr_leave < "database\seeds.sql" 2>nul
if errorlevel 1 (
    mysql -u root -p ali_hr_leave < "database\seeds.sql"
    if errorlevel 1 (
        echo ERROR: Could not import seed data
        pause
        exit /b 1
    )
)
echo Seed data imported successfully!
echo.

echo ========================================
echo DATABASE SETUP COMPLETE!
echo ========================================
echo.
echo You can now login with these credentials:
echo.
echo SUPER ADMIN:
echo   Email: admin@ali-hr.com
echo   Password: Admin@123
echo.
echo HR USER:
echo   Email: hr@ali-hr.com
echo   Password: Hr@123
echo.
echo MANAGER:
echo   Email: manager@ali-hr.com
echo   Password: Manager@123
echo.
echo EMPLOYEE:
echo   Email: employee@ali-hr.com
echo   Password: Employee@123
echo.
echo ========================================
echo.
echo Server should be running at: http://localhost:3000
echo If not, run: RUN_ME_NOW.bat
echo.
pause
