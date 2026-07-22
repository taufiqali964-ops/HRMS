@echo off
echo ========================================
echo Validating Code Fixes
echo ========================================
echo.

set ERROR_COUNT=0

echo Checking API route files for naming conflicts...
echo.

REM Check each fixed file
echo Checking users/route.js...
findstr /C:"async function GET" "app\api\users\route.js" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] users/route.js still has naming conflict!
    set /a ERROR_COUNT+=1
) else (
    echo [OK] users/route.js
)

echo Checking users/[id]/route.js...
findstr /C:"async function PUT" "app\api\users\[id]\route.js" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] users/[id]/route.js still has naming conflict!
    set /a ERROR_COUNT+=1
) else (
    echo [OK] users/[id]/route.js
)

echo Checking leave-quotas/route.js...
findstr /C:"async function GET" "app\api\leave-quotas\route.js" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] leave-quotas/route.js still has naming conflict!
    set /a ERROR_COUNT+=1
) else (
    echo [OK] leave-quotas/route.js
)

echo Checking leave-quotas/[id]/route.js...
findstr /C:"async function PUT" "app\api\leave-quotas\[id]\route.js" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] leave-quotas/[id]/route.js still has naming conflict!
    set /a ERROR_COUNT+=1
) else (
    echo [OK] leave-quotas/[id]/route.js
)

echo Checking leave-approvals/route.js...
findstr /C:"async function POST" "app\api\leave-approvals\route.js" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] leave-approvals/route.js still has naming conflict!
    set /a ERROR_COUNT+=1
) else (
    echo [OK] leave-approvals/route.js
)

echo Checking leave-balances/route.js...
findstr /C:"async function GET" "app\api\leave-balances\route.js" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] leave-balances/route.js still has naming conflict!
    set /a ERROR_COUNT+=1
) else (
    echo [OK] leave-balances/route.js
)

echo Checking leave-ledger/route.js...
findstr /C:"async function GET" "app\api\leave-ledger\route.js" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] leave-ledger/route.js still has naming conflict!
    set /a ERROR_COUNT+=1
) else (
    echo [OK] leave-ledger/route.js
)

echo Checking notifications/route.js...
findstr /C:"async function GET" "app\api\notifications\route.js" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] notifications/route.js still has naming conflict!
    set /a ERROR_COUNT+=1
) else (
    echo [OK] notifications/route.js
)

echo Checking reports/route.js...
findstr /C:"async function GET" "app\api\reports\route.js" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] reports/route.js still has naming conflict!
    set /a ERROR_COUNT+=1
) else (
    echo [OK] reports/route.js
)

echo Checking reports/utilisation/route.js...
findstr /C:"async function GET" "app\api\reports\utilisation\route.js" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] reports/utilisation/route.js still has naming conflict!
    set /a ERROR_COUNT+=1
) else (
    echo [OK] reports/utilisation/route.js
)

echo.
echo ========================================
if %ERROR_COUNT%==0 (
    echo VALIDATION PASSED! ✓
    echo All fixes are properly applied.
    echo You can now run: npm run build
) else (
    echo VALIDATION FAILED!
    echo Found %ERROR_COUNT% file(s) with naming conflicts.
    echo Please review the errors above.
)
echo ========================================
echo.
pause
