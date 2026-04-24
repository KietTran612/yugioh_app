@echo off
echo ================================
echo  Yu-Gi-Oh! Card App - Web Runner
echo ================================
echo.

set FLUTTER=D:\Download\flutter\bin\flutter.bat
set APP_DIR=%~dp0yugioh_card_app

:: Check Flutter exists
if not exist "%FLUTTER%" (
    echo [ERROR] Flutter not found at %FLUTTER%
    echo Please update the FLUTTER path in this script.
    pause
    exit /b 1
)

:: Navigate to app directory
cd /d "%APP_DIR%"

echo [1/2] Getting dependencies...
call "%FLUTTER%" pub get
if errorlevel 1 (
    echo [ERROR] flutter pub get failed.
    pause
    exit /b 1
)

echo.
echo [2/2] Starting app on Chrome at http://localhost:8080
echo.
echo  Press 'r' to hot reload
echo  Press 'R' to hot restart
echo  Press 'q' to quit
echo.

call "%FLUTTER%" run -d chrome --web-port 8080 --web-browser-flag "--disable-web-security"

pause
