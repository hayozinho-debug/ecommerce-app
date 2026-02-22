@echo off
echo ========================================
echo    Reconstruindo APK Android
echo ========================================
echo.

cd mobile

echo [1/4] Limpando build anterior...
call flutter clean

echo.
echo [2/4] Baixando dependencias...
call flutter pub get

echo.
echo [3/4] Construindo APK (Release)...
call flutter build apk --release

echo.
echo [4/4] APK pronto!
echo.
echo ========================================
echo Localizacao do APK:
echo %CD%\build\app\outputs\flutter-apk\app-release.apk
echo ========================================
echo.
echo Para instalar no celular via USB:
echo adb install build\app\outputs\flutter-apk\app-release.apk
echo.
echo Ou copie o arquivo para o celular e instale manualmente.
echo.
pause
