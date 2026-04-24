@echo off
echo ================================
echo  YUCA - Build Release APK
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
echo [2/2] Building Release APK (arm64 only, optimized)...
echo  Note: Release APK is small (~15-25MB), minified and obfuscated.
echo.

call "%FLUTTER%" build apk --release --target-platform android-arm64 --obfuscate --split-debug-info=build\debug-info
if errorlevel 1 (
    echo [ERROR] Build failed.
    pause
    exit /b 1
)

echo.
echo ================================
echo  BUILD SUCCESS
echo ================================
echo  Output: %OUTPUT_DIR%\app-release.apk
echo.
echo  Debug symbols saved to: %APP_DIR%\build\debug-info
echo  (Keep these to decode crash stack traces later)
echo.

:: Show file size
for %%F in ("%OUTPUT_DIR%\app-release.apk") do (
    set /a SIZE=%%~zF / 1048576
    echo  Size: !SIZE! MB
)

echo.
echo  Install on connected device? (requires adb in PATH)
set /p INSTALL="  Type 'y' to install via ADB, or press Enter to skip: "
if /i "%INSTALL%"=="y" (
    echo.
    echo  Installing...
    adb install -r "%OUTPUT_DIR%\app-release.apk"
)

echo.
pause
