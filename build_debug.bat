@echo off
echo ================================
echo  YUCA - Build Debug APK
echo ================================
echo.

set FLUTTER=D:\Download\flutter\bin\flutter.bat
set APP_DIR=%~dp0yugioh_card_app
set OUTPUT_DIR=%APP_DIR%\build\app\outputs\flutter-apk

:: Check Flutter exists
if not exist "%FLUTTER%" (
    echo [ERROR] Flutter not found at %FLUTTER%
    echo Please update the FLUTTER path in this script.
    pause
    exit /b 1
)

cd /d "%APP_DIR%"

echo [1/2] Getting dependencies...
call "%FLUTTER%" pub get
if errorlevel 1 (
    echo [ERROR] flutter pub get failed.
    pause
    exit /b 1
)

echo.
echo [2/2] Building Debug APK (all ABIs)...
echo  Note: Debug APK is large (~150MB) but supports hot reload via USB.
echo.

call "%FLUTTER%" build apk --debug
if errorlevel 1 (
    echo [ERROR] Build failed.
    pause
    exit /b 1
)

echo.
echo ================================
echo  BUILD SUCCESS
echo ================================
echo  Output: %OUTPUT_DIR%\app-debug.apk
echo.

:: Show file size
for %%F in ("%OUTPUT_DIR%\app-debug.apk") do (
    set /a SIZE=%%~zF / 1048576
    echo  Size: !SIZE! MB
)

echo.
echo  Install on connected device? (requires adb in PATH)
set /p INSTALL="  Type 'y' to install via ADB, or press Enter to skip: "
if /i "%INSTALL%"=="y" (
    echo.
    echo  Installing...
    adb install -r "%OUTPUT_DIR%\app-debug.apk"
)

echo.
pause
