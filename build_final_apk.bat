@echo off
echo ===================================
echo Building Montajati Production APK
echo ===================================
echo.

:: Check Flutter
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found
    pause
    exit /b 1
)

echo Flutter found
flutter --version
echo.

:: Navigate to frontend
if not exist "frontend" (
    echo ERROR: frontend folder not found
    pause
    exit /b 1
)

cd frontend
echo Navigating to frontend folder
echo.

:: Clean project
echo Cleaning project...
flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Failed to clean project
    pause
    exit /b 1
)
echo Project cleaned successfully
echo.

:: Get dependencies
echo Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)
echo Dependencies updated successfully
echo.

:: Build APK for production
echo Building production APK...
echo This may take several minutes...
echo.

flutter build apk --release --verbose
if %errorlevel% neq 0 (
    echo ERROR: Failed to build APK
    pause
    exit /b 1
)

echo.
echo APK built successfully!
echo.

:: Build App Bundle for Play Store
echo Building App Bundle for Play Store...
flutter build appbundle --release --verbose
if %errorlevel% neq 0 (
    echo WARNING: Failed to build App Bundle
    echo But APK is ready for use
) else (
    echo App Bundle built successfully!
)

echo.
echo ===================================
echo BUILD COMPLETED SUCCESSFULLY!
echo ===================================
echo.

:: Show file information
echo Generated files:
echo.

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo APK for direct distribution:
    echo    Location: frontend\build\app\outputs\flutter-apk\app-release.apk
    for %%A in ("build\app\outputs\flutter-apk\app-release.apk") do echo    Size: %%~zA bytes
    echo.
)

if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo App Bundle for Play Store:
    echo    Location: frontend\build\app\outputs\bundle\release\app-release.aab
    for %%A in ("build\app\outputs\bundle\release\app-release.aab") do echo    Size: %%~zA bytes
    echo.
)

:: App information
echo App Information:
echo    Name: Montajati
echo    Package ID: com.montajati.app
echo    Version: 2.1.0 (Build 7)
echo    Target SDK: Android 15 (API 35)
echo    Min SDK: Android 5.0 (API 21)
echo.

:: Installation instructions
echo Installation Instructions:
echo.
echo For Android device installation:
echo    1. Copy app-release.apk to device
echo    2. Enable "Unknown sources" in security settings
echo    3. Tap the file to install
echo.
echo For Google Play Store:
echo    1. Use app-release.aab file
echo    2. Upload to Google Play Console
echo    3. Follow store publishing steps
echo.

:: Open files folder
echo Opening files folder...
if exist "build\app\outputs\flutter-apk\" (
    start "" "build\app\outputs\flutter-apk\"
)

echo.
echo App is ready for production!
echo.
pause
