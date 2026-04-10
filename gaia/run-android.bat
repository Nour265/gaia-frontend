@echo off
REM Auto-detect machine IP and run Flutter with Android device server config

REM Get the WiFi IPv4 address
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /C:"IPv4 Address"') do (
    set IP=%%A
    goto :found
)

:found
REM Trim whitespace from IP
for /f "tokens=* delims= " %%A in ("%IP%") do set IP=%%A

if "%IP%"=="" (
    echo Error: Could not detect your IP address
    echo Please run 'ipconfig' manually and check your IPv4 address
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Detected Your Machine IP: %IP%
echo ==========================================
echo.
echo Starting Flutter for physical Android device...
echo API Server: http://%IP%:8000
echo.
echo Make sure:
echo   1. Your backend is running on port 8000
echo   2. Your phone is on the same WiFi network
echo.

REM Navigate to Flutter project directory
cd /d "%~dp0"

REM Run Flutter with the detected IP
flutter clean
flutter pub get
flutter run --dart-define=API_BASE_URL=http://%IP%:8000

pause
