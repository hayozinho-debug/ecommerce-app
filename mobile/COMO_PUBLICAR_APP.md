# 📱 Como Publicar o App - Guia Rápido

## 🔧 Passo 1: Configurar para Produção

Abra o arquivo `lib/constants/app_constants.dart` e altere:

```dart
static const bool isProduction = false;  // ❌ DESENVOLVIMENTO
```

Para:

```dart
static const bool isProduction = true;  // ✅ PRODUÇÃO
```

## 🏗️ Passo 2: Gerar o APK

Execute no terminal:

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
```

O APK estará em: `mobile/build/app/outputs/flutter-apk/app-release.apk`

## 📤 Passo 3: Publicar na Play Store

1. Acesse: https://play.google.com/console
2. Crie um novo aplicativo
3. Faça upload do APK gerado
4. Preencha as informações do app (descrição, screenshots, etc.)
5. Envie para revisão

## ⚠️ IMPORTANTE: Após publicar

**VOLTE para desenvolvimento** alterando novamente:

```dart
static const bool isProduction = false;  // ✅ DESENVOLVIMENTO
```

Isso garante que você continue testando localmente sem afetar a produção.

## 🔄 URLs do Backend

| Ambiente | URL |
|----------|-----|
| **Desenvolvimento** | `http://192.168.5.4:3000/api` |
| **Produção** | `https://ecommerce-api.onrender.com/api` |

## 📝 Checklist Before Deploy

- [ ] Backend rodando no Render.com
- [ ] `isProduction = true` no app_constants.dart
- [ ] Testou o app em modo release localmente
- [ ] Versão atualizada no pubspec.yaml
- [ ] APK gerado com `flutter build apk --release`

---

💡 **Dica:** Para testar o app em modo produção antes de publicar, construa o APK com `isProduction = true` e instale no seu celular para testar se está tudo funcionando corretamente.
