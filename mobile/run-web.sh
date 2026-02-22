#!/bin/bash

# 🌐 Script para rodar Flutter Web corretamente (sem refresh infinito)

echo "🧹 Limpando cache do Flutter..."
flutter clean

echo "📦 Obtendo dependências..."
flutter pub get

echo "🌐 Iniciando Flutter Web (Chrome) com configurações otimizadas..."
echo ""
echo "⚠️  IMPORTANTE: Se o refresh infinito continuar:"
echo "   1. Feche TODAS as janelas do Chrome"
echo "   2. Execute novamente este script"
echo ""
echo "🚀 Iniciando em 3 segundos..."
sleep 3

# Rodar com hot reload desabilitado para evitar loops
flutter run -d chrome --web-port=8080 --web-renderer html --no-sound-null-safety

# Alternativa: Se ainda tiver problemas, use este comando:
# flutter run -d chrome --web-port=8080 --web-renderer html --release
