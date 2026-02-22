# Correção de Conexão do App Android com API Local

## Problema Identificado

O app Android instalado (APK) não conseguia se conectar à API local `http://192.168.5.4:3000/api`, mesmo o navegador do celular conseguindo acessar.

## Causa Raiz

Por padrão, o Android (a partir da versão 9) **bloqueia conexões HTTP não criptografadas** (cleartext traffic) por razões de segurança. O app precisa de configurações específicas para permitir conexões HTTP durante o desenvolvimento.

## Correções Aplicadas

### 1. AndroidManifest.xml - Permissões e Configurações

**Arquivo:** `mobile/android/app/src/main/AndroidManifest.xml`

✅ Adicionadas permissões:
- `INTERNET` - Permite acesso à internet
- `ACCESS_NETWORK_STATE` - Permite verificar status da rede

✅ Configurações no `<application>`:
- `android:usesCleartextTraffic="true"` - Permite HTTP
- `android:networkSecurityConfig="@xml/network_security_config"` - Referencia arquivo de segurança

### 2. Network Security Config

**Arquivo:** `mobile/android/app/src/main/res/xml/network_security_config.xml`

Criado arquivo de configuração de segurança de rede que:
- ✅ Permite tráfego HTTP claro para desenvolvimento
- ✅ Configura domínios específicos (IPs locais)
- ✅ Mantém certificados do sistema confiáveis

**Domínios permitidos:**
- `192.168.5.4` (seu IP local)
- `localhost`
- `10.0.2.2` (emulador Android)

## Como Reconstruir o APK

### Opção 1: APK de Debug (Recomendado para testes)

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --debug
```

O APK estará em: `mobile/build/app/outputs/flutter-apk/app-debug.apk`

### Opção 2: APK de Release

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
```

O APK estará em: `mobile/build/app/outputs/flutter-apk/app-release.apk`

### Opção 3: Build Otimizado (Split APKs por arquitetura)

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --split-per-abi --release
```

Gera APKs separados:
- `app-armeabi-v7a-release.apk` (32-bit)
- `app-arm64-v8a-release.apk` (64-bit) - **Recomendado para celulares modernos**
- `app-x86_64-release.apk` (emuladores)

## Instalação no Celular

### Via USB (ADB)

```bash
# Conecte o celular via USB com depuração USB ativada
adb install mobile/build/app/outputs/flutter-apk/app-release.apk
```

### Via Transferência de Arquivo

1. Copie o APK para o celular
2. Abra o arquivo no celular
3. Permita instalação de fontes desconhecidas (se necessário)
4. Instale o app

## Verificações Importantes

### 1. Certifique-se que o servidor está rodando

```bash
# No diretório raiz do projeto
npm run dev
```

O servidor deve estar em: `http://192.168.5.4:3000`

### 2. Verifique se o IP está correto

Em `mobile/lib/constants/app_constants.dart`:
```dart
static const String apiUrl = 'http://192.168.5.4:3000/api';
```

**⚠️ IMPORTANTE:** Use o IP real da sua máquina na rede local, não use `localhost`.

Para descobrir seu IP:

**Windows:**
```bash
ipconfig
```
Procure por "Endereço IPv4" na sua conexão de rede ativa.

**Linux/Mac:**
```bash
ifconfig
# ou
ip addr show
```

### 3. Firewall

Certifique-se de que o firewall do Windows/antivírus não está bloqueando conexões na porta 3000.

### 4. Mesma Rede

O celular e o computador **DEVEM** estar na mesma rede Wi-Fi.

## Teste Rápido no Navegador do Celular

Antes de testar o app, verifique no navegador do celular:

```
http://192.168.5.4:3000/api/shopify/products
```

Se funcionar no navegador mas não no app, reconstrua o APK com as novas configurações.

## Troubleshooting

### Problema: "Connection refused" ou "Network error"

**Soluções:**
1. ✅ Verifique se o servidor está rodando (`npm run dev`)
2. ✅ Confirme que está usando o IP correto (não localhost)
3. ✅ Reconstrua o APK (`flutter build apk --release`)
4. ✅ Desinstale o app antigo e instale o novo APK
5. ✅ Verifique o firewall

### Problema: "Cleartext HTTP traffic not permitted"

**Solução:**
- As configurações já foram aplicadas
- Reconstrua o APK completamente: `flutter clean && flutter build apk`

### Problema: App instalado mas continua com erro

**Solução:**
1. Desinstale o app completamente do celular
2. Execute `flutter clean` na pasta mobile
3. Reconstrua: `flutter build apk --release`
4. Instale o novo APK

## Notas de Segurança

⚠️ **IMPORTANTE:** Estas configurações são para **DESENVOLVIMENTO LOCAL**.

Para produção, você deve:
- Usar HTTPS (SSL/TLS)
- Remover `android:usesCleartextTraffic="true"`
- Usar um domínio real com certificado SSL
- Configurar o `network_security_config.xml` adequadamente

## Comandos Resumidos

```bash
# 1. Limpar e reconstruir
cd mobile
flutter clean
flutter pub get

# 2. Construir APK
flutter build apk --release

# 3. Instalar no celular (via USB)
adb install build/app/outputs/flutter-apk/app-release.apk

# 4. Verificar se está rodando OK
adb logcat | grep flutter
```

## Checklist Final

- [ ] Servidor rodando em `http://192.168.5.4:3000`
- [ ] IP correto em `app_constants.dart`
- [ ] AndroidManifest.xml atualizado
- [ ] network_security_config.xml criado
- [ ] APK reconstruído com `flutter build apk`
- [ ] App antigo desinstalado do celular
- [ ] Novo APK instalado
- [ ] Celular e PC na mesma rede Wi-Fi
- [ ] Firewall não bloqueando porta 3000

✅ Se todos os itens estiverem OK, o app deve conectar com sucesso!
