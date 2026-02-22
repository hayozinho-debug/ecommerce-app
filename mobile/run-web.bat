@echo off
REM 🌐 Script para rodar Flutter Web corretamente (sem refresh infinito) - Windows

echo 🧹 Limpando cache do Flutter...
flutter clean

echo 📦 Obtendo dependências...
flutter pub get

echo.
echo 🌐 Iniciando Flutter Web (Chrome) com configurações otimizadas...
echo.
echo ⚠️  IMPORTANTE: Se o refresh infinito continuar:
echo    1. Feche TODAS as janelas do Chrome
echo    2. Execute novamente este script
echo    3. Ou use o modo release (mais estável)
echo.
echo 🚀 Iniciando...
echo.

REM Rodar com configurações que evitam refresh infinito
flutter run -d chrome --web-port=8080 --web-renderer html

REM Se ainda tiver problemas, use o modo release (descomente a linha abaixo):
REM flutter run -d chrome --web-port=8080 --web-renderer html --release
