# 🌐 Solucionando Refresh Infinito - Flutter Web

## 🐛 Problema
Ao executar `flutter run -d chrome`, a página fica eternamente dando refresh.

---

## ✅ Soluções (em ordem de prioridade)

### 🥇 Solução 1: Usar o Script Otimizado (Recomendado)

**Windows:**
```bash
cd mobile
run-web.bat
```

**Linux/Mac:**
```bash
cd mobile
chmod +x run-web.sh
./run-web.sh
```

---

### 🥈 Solução 2: Comando Manual Otimizado

```bash
cd mobile
flutter clean
flutter pub get
flutter run -d chrome --web-port=8080 --web-renderer html
```

**Se ainda tiver problema, use o modo release:**
```bash
flutter run -d chrome --web-port=8080 --web-renderer html --release
```

---

### 🥉 Solução 3: Fechar Todas as Instâncias do Chrome

O Chrome pode manter conexões antigas que causam o loop.

**Windows:**
```powershell
taskkill /F /IM chrome.exe
flutter run -d chrome
```

**Linux/Mac:**
```bash
killall chrome
flutter run -d chrome
```

---

### 🎯 Solução 4: Usar Outro Navegador

#### Microsoft Edge:
```bash
flutter run -d edge --web-port=8080
```

#### Firefox (precisa habilitar primeiro):
```bash
flutter config --enable-web
flutter run -d web-server --web-port=8080
# Depois abra manualmente: http://localhost:8080
```

---

### 🔧 Solução 5: Desabilitar Hot Reload

Adicione no `mobile/analysis_options.yaml`:

```yaml
analyzer:
  errors:
    invalid_assignment: warning
    missing_return: error
    dead_code: info

linter:
  rules:
    - prefer_const_constructors
```

E rode com:
```bash
flutter run -d chrome --no-hot
```

---

## 🎬 Solução 6: Problema com Video Player

Se o refresh acontece especificamente na tela de vídeos, o problema é o `video_player_web`.

**Desabilite vídeos temporariamente:**

Em `lib/widgets/clips_stories_widget.dart`, adicione uma flag:

```dart
class ClipsStoriesWidget extends StatefulWidget {
  final bool enableVideos; // Nova flag
  
  const ClipsStoriesWidget({
    Key? key,
    this.enableVideos = true, // Padrão: habilitado
  }) : super(key: key);
}
```

E no `lib/screens/home_additional.dart`, use:

```dart
// Desabilitar vídeos no web
ClipsStoriesWidget(
  enableVideos: !kIsWeb, // Só habilita em mobile
)
```

---

## 🔍 Diagnóstico: Identificar a Causa

### 1. Verificar se é problema de hot reload
```bash
flutter run -d chrome --release
```
✅ Se funcionar: Problema é o hot reload  
❌ Se continuar: Problema é no código

### 2. Verificar se é problema com vídeos
Comente temporariamente o `ClipsStoriesWidget` na home.

✅ Se parar: Problema é o video player  
❌ Se continuar: Problema está em outro widget

### 3. Verificar logs
Abra o DevTools do Chrome (F12) e veja se há:
- ❌ Erros de CORS
- ❌ Erros de conexão com API
- ❌ Loops de setState

---

## ⚙️ Configurações Recomendadas

### Para Desenvolvimento Web

Crie ou edite `mobile/lib/main.dart`:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  // Desabilitar alguns recursos pesados no web
  if (kIsWeb) {
    // Configurações específicas para web
  }
  runApp(const MyApp());
}
```

---

## 🚀 Melhor Prática

**Para desenvolver:**  
✅ Use **dispositivo físico ou emulador Android/iOS**  
❌ Evite desenvolver no Chrome (muito instável para apps complexos)

**Para testar no navegador:**  
✅ Use **modo release** ou **build web**

```bash
# Build e sirva localmente
cd mobile
flutter build web --release
python -m http.server 8000 -d build/web

# Depois abra: http://localhost:8000
```

---

## 🎯 Comando Recomendado Final

```bash
cd mobile
flutter run -d chrome --web-renderer html --release
```

Ou simplesmente:
```bash
cd mobile
run-web.bat  # Windows
./run-web.sh # Linux/Mac
```

---

## 📱 Alternativa: Desenvolver no Android/iOS

**Muito mais estável:**

```bash
cd mobile

# Android
flutter run -d <device-id>

# iOS (Mac apenas)
flutter run -d ios

# Ver dispositivos disponíveis
flutter devices
```

---

## 💡 Dica Final

Se você está desenvolvendo o app mobile, **não precisa testar no Chrome**. O Flutter web é bom para testar responsividade, mas o app foi feito para Android/iOS.

**Melhor fluxo:**
1. Desenvolva e teste no emulador Android
2. Gere o APK quando estiver pronto
3. Instale no celular real para testes finais

```bash
cd mobile
flutter build apk --release
```

O APK estará em: `build/app/outputs/flutter-apk/app-release.apk`
