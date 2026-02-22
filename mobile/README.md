# Ecommerce Moda - App Mobile (Flutter)

App mobile para iOS e Android para uma loja de roupas e moda, conectado à API Node.js backend.

## 📱 Features

✅ Autenticação (Login/Registro)
✅ Listagem de Produtos
✅ Detalhes do Produto com Variantes
✅ Carrinho de Compras
✅ Checkout
✅ Histórico de Pedidos
✅ Armazenamento Local (SharedPreferences)
✅ Design Material 3

## 🛠️ Requisitos

- Flutter 3.0+
- Dart 3.0+
- iOS 12+ (para publicar na App Store)
- Android 5.0+ (para publicar na Play Store)

## ⚙️ Setup

### 1. Instale Flutter

Baixe em: https://flutter.dev/docs/get-started/install

Após instalar, verifique:
```bash
flutter --version
dart --version
```

### 2. Clone/Configure o Projeto

```bash
cd c:\ecommerce-app\mobile
```

### 3. Instale Dependências

```bash
flutter pub get
```

### 4. Configure a API

Abra `lib/constants/app_constants.dart` e ajuste `apiUrl` se necessário:

```dart
static const String apiUrl = 'http://localhost:3000/api';
```

> **Importante**: Para testar em dispositivo físico/emulador, use o IP da sua máquina em vez de `localhost`.

Descubra seu IP:
```bash
ipconfig
```

Use o IPv4 dessa máquina:
```dart
static const String apiUrl = 'http://192.168.X.X:3000/api';
```

## 🚀 Executar Aplicação

### No Emulador Android

```bash
flutter emulators
flutter emulators launch <emulator_name>
flutter run
```

### No Simulador iOS (macOS apenas)

```bash
open -a Simulator
flutter run
```

### Em Dispositivo Físico

Conecte seu dispositivo via USB/WiFi:
```bash
flutter devices
flutter run -d <device_id>
```

## 📁 Estrutura do Projeto

```
mobile/
├── lib/
│   ├── main.dart                  # Entrypoint
│   ├── constants/
│   │   └── app_constants.dart     # URLs e constantes
│   ├── models/
│   │   ├── user.dart              # Model User
│   │   ├── product.dart           # Model Product
│   │   ├── cart_item.dart         # Model CartItem
│   │   └── order.dart             # Model Order
│   ├── providers/
│   │   ├── auth_provider.dart     # Gerenciamento de autenticação
│   │   ├── product_provider.dart  # Gerenciamento de produtos
│   │   └── cart_provider.dart     # Gerenciamento de carrinho
│   └── screens/
│       ├── splash_screen.dart     # Tela de splash
│       ├── login_screen.dart      # Login
│       ├── register_screen.dart   # Registro
│       ├── home_additional.dart   # Home com navegação
│       ├── products_screen.dart   # Produtos e catálogo
│       ├── product_detail_screen.dart  # Detalhe do produto
│       ├── cart_screen.dart       # Carrinho com gamificação
│       └── checkout_webview.dart  # Checkout
├── pubspec.yaml                   # Dependências
└── README.md
```

## 🔐 Credenciais de Teste

Após da API ter seed rodado, use:

| Email | Senha |
|-------|-------|
| `user@example.com` | `password123` |
| `admin@example.com` | `password123` |

## 📱 Telas Disponíveis

### 1. **Splash Screen**
- Exibida enquanto a autenticação é verificada

### 2. **Login**
- Login com email/senha
- Link para registrar

### 3. **Registro**
- Criar nova conta
- Validação de campos

### 4. **Home (Produtos)**
- Grid de produtos
- Adicionar ao carrinho rápido
- Pull-to-refresh

### 5. **Detalhes do Produto**
- Imagem ampliada
- Descrição
- Seleção de variantes (tamanho/cor)
- Quantidade ajustável
- Adicionar ao carrinho

### 6. **Carrinho**
- Listar itens
- Ajustar quantidade
- Remover itens
- Total
- Checkout (criar pedido)

## 🔌 Dependências

- **provider**: State management
- **http**: Requisições HTTP
- **shared_preferences**: Armazenamento local
- **intl**: Internacionalização

## 🚢 Publicar na App Store / Play Store

### Android (Play Store)

1. Crie um keystore:
```bash
keytool -genkey -v -keystore ~/ecommerce_key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias ecommerce
```

2. Gere APK assinado:
```bash
flutter build apk --release
```

3. Upload para Play Store Console

### iOS (App Store)

1. Configure no Xcode:
```bash
cd ios
pod install
cd ..
```

2. Gere build:
```bash
flutter build ipa --release
```

3. Upload para App Store Connect

## 🔧 Troubleshooting

### Erro: "Unable to connect to API"
- Verifique se o backend está rodando em `http://localhost:3000`
- Em emulador, use o IP da máquina em vez de `localhost`
- Verifique firewall/acesso de rede

### Erro: "CORS error"
- No backend, adicione headers CORS em `src/server.ts`

### Erro: "Gradle build failed"
- Execute: `flutter clean && flutter pub get`
- Se persistir: `rm -rf android/build && flutter build apk`

## 📝 Fluxo de Desenvolvimento

1. ✅ Flutter scaffold criado
2. ✅ Models (User, Product, Cart, Order)
3. ✅ Providers (Auth, Product, Cart)
4. ✅ Telas (Login, Home, Produtos, Carrinho, etc)
5. ⏳ Testes automatizados (integração com backend)
6. ⏳ Publicação em App Store / Play Store

## 🎯 Próximos Passos

- [ ] Testes automatizados
- [ ] Integração com Stripe
- [ ] Notificações Push
- [ ] Filtros e busca avançada
- [ ] Avaliações de produtos
- [ ] Histórico de pedidos completo
- [ ] Perfil do usuário
- [ ] Dark mode

## 📄 Licença

MIT

---

**Desenvolvido com ❤️ em Flutter**
