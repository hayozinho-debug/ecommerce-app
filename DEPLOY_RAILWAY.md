# 🚂 Deploy no Railway - Guia Completo

## ✨ Por que Railway?
- ✅ **$5/mês grátis** (mais que suficiente)
- ✅ **Não dorme** (sempre ativo)
- ✅ **PostgreSQL incluído** (sem custos extras)
- ✅ **Timeout 5min** (vs 30s de concorrentes)
- ✅ Deploy em **1 clique** via GitHub
- ✅ Altamente estável e profissional

---

## 📋 Pré-requisitos
- ✅ Conta no GitHub
- ✅ Código commitado no GitHub
- ✅ Cartão de crédito (para verificação, não será cobrado inicialmente)

---

## 🎯 Passo a Passo

### 1️⃣ Preparar o Repositório GitHub

```bash
cd c:\ecommerce-app
git init
git add .
git commit -m "Deploy para Railway"

# Criar repositório no GitHub e fazer push
git remote add origin https://github.com/SEU_USUARIO/ecommerce-app.git
git branch -M main
git push -u origin main
```

---

### 2️⃣ Criar Conta no Railway

1. Acesse: **https://railway.app**
2. Clique em **"Login with GitHub"**
3. Autorize o Railway
4. Adicione seu **cartão de crédito** para verificação
   - ⚠️ Não será cobrado com o crédito grátis de $5
   - 💳 Só cobra se ultrapassar o $5

---

### 3️⃣ Criar um Novo Projeto

1. No dashboard, clique em **"New Project"**
2. Selecione **"Deploy from GitHub repo"**
3. Conecte seu repositório `ecommerce-app`
4. Selecione a **branch `main`**

---

### 4️⃣ Criar Serviço Node.js

1. Após conectar o repositório, clique em **"Add Service"**
2. Selecione **"GitHub Repo"**
3. Configure:
   - **Service Name:** `ecommerce-api`
   - **Root Directory:** deixe em branco (raiz do projeto)

O Railway vai detectar automaticamente que é um projeto Node.js.

---

### 5️⃣ Adicionar PostgreSQL

1. No dashboard do projeto, clique em **"Add Service"**
2. Selecione **"PostgreSQL"**
3. O Railway cria automáticamente um banco de dados com:
   - Host
   - Port
   - Username
   - Password
   - Database name

---

### 6️⃣ Configurar Variáveis de Ambiente

#### 📌 Conectar PostgreSQL Automaticamente

O Railway faz isso **automaticamente**! 🎉

Quando você adiciona PostgreSQL, ele cria uma variável `DATABASE_URL` que o seu backend pode usar.

#### 🔧 Adicionar Outras Variáveis

No dashboard do serviço Node.js, clique em **"Variables"** e adicione:

| Key | Value | Obrigatório |
|-----|-------|------------|
| `NODE_ENV` | `production` | ✅ Sim |
| `PORT` | `3000` | ✅ Sim |
| `JWT_SECRET` | `seu_jwt_super_secreto_mudado` | ✅ Sim |
| `SHOPIFY_STORE_DOMAIN` | `brazlucca.myshopify.com` | ✅ Sim |
| `SHOPIFY_STOREFRONT_TOKEN` | `9b170957a5e834043ef1f0c0d449c180` | ✅ Sim |
| `SHOPIFY_API_VERSION` | `2024-10` | ✅ Sim |

---

### 7️⃣ Configurar Build e Deploy

O Railway detecta `package.json` automaticamente. Configure:

**No arquivo `package.json`, certifique-se de ter:**

```json
{
  "scripts": {
    "build": "tsc",
    "start": "node dist/server.js",
    "dev": "ts-node-dev src/server.ts --respawn --transpile-only",
    "postinstall": "prisma generate"
  }
}
```

O Railway vai rodar:
1. `npm install`
2. `npm run build` (build automático)
3. `npm start` (iniciar o servidor)

---

### 8️⃣ Deploy

1. Clique em **"Deploy"** no dashboard
2. Aguarde 2-5 minutos
3. Quando ficar verde ✅, seu backend está online!

A URL será algo como:
```
https://ecommerce-api-production-xxxx.up.railway.app
```

---

### 9️⃣ Testar a API

Acesse no navegador ou Postman:
```
https://sua-url-railway.up.railway.app/api/shopify/products
```

Você deve ver a lista de produtos em JSON.

---

## 📱 Atualizar o App Flutter

### Passo 1: Copiar a URL de Produção

No dashboard do Railway, copie a URL do seu app (algo como: `https://ecommerce-api-production-xxxx.up.railway.app`)

### Passo 2: Atualizar app_constants.dart

Abra `mobile/lib/constants/app_constants.dart` e atualize:

```dart
static const String _productionUrl = 'https://sua-url-railway.up.railway.app/api';
```

### Passo 3: Preparar para Produção

Altere a flag:
```dart
static const bool isProduction = true;
```

### Passo 4: Gerar o APK

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
```

O APK estará em: `mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## 🔄 Deploy Automático

O Railway faz **deploy automático** sempre que você faz push no GitHub:

```bash
# Fazer alterações no código
git add .
git commit -m "Atualização do backend"
git push

# O Railway detecta e faz deploy automático! 🎉
```

---

## 🛠️ Comandos Úteis no Railway

### Ver Logs
No dashboard, clique em **"Logs"** para ver erros e informações em tempo real.

### Reiniciar o Serviço
Clique em **"More"** → **"Restart"**

### Acessar Variáveis
Clique em **"Variables"** para ver e editar variáveis de ambiente.

### Conectar ao Banco de Dados
Railway oferece uma interface web para gerenciar o PostgreSQL.

---

## 🐛 Solução de Problemas

### ❌ Build falhou

**Erro:** `Module not found` ou `Cannot find module`

**Solução:**
```bash
npm install
npm run build
git add package.json package-lock.json
git commit -m "Atualizar dependências"
git push
```

### ❌ Prisma não inicializa

Adicione no `package.json`:
```json
"postinstall": "prisma generate"
```

E faça:
```bash
git add package.json
git commit -m "Adicionar postinstall"
git push
```

### ❌ Database connection failed

**Solução:** Railway cria a variável `DATABASE_URL` automaticamente. Se não funcionar:

1. Vá em **"Variables"** no serviço PostgreSQL
2. Copie o `DATABASE_URL`
3. Cole no serviço Node.js

### ❌ Porta já em uso

Railway usa porta 3000 automaticamente. Se houver conflito:

```json
"start": "node dist/server.js"
```

Certifique-se que seu código usa `process.env.PORT || 3000`.

---

## 📊 Monitoramento

Railroad fornece:
- ✅ Logs em tempo real
- ✅ Métricas de CPU/RAM
- ✅ Histórico de deploys
- ✅ Alertas de erro

Acesse tudo no dashboard: **https://railway.app**

---

## 💰 Custos

### Com $5 grátis/mês você cobre:

```
CPU/RAM (runtime):           ~$2-3/mês
PostgreSQL (5GB storage):     ~$0.50/mês
Network egress:               ~$0.50/mês
                    ────────────────────
TOTAL:                        ~$3-4/mês
```

✅ **Sobra $1/mês de margem**

### Quando vai além dos $5?

- 📈 Se tiver **muito tráfego** (100k+ requests/mês)
- 📊 Se aumentar **drasticamente o storage**
- ⚡ Se rodar múltiplas replicas

Para um e-commerce começando, **$5 cobre tudo**! 🎉

---

## 🔐 Segurança

**⚠️ NUNCA commite secrets no GitHub!**

Use as variáveis de ambiente do Railway para:
- `JWT_SECRET`
- `SHOPIFY_STOREFRONT_TOKEN`
- Qualquer outra chave privada

---

## 📌 Próximos Passos

- [ ] Criar conta no Railway.app
- [ ] Conectar repositório GitHub
- [ ] Adicionar PostgreSQL
- [ ] Configurar variáveis de ambiente
- [ ] Deploy inicial
- [ ] Copiar URL de produção
- [ ] Atualizar app_constants.dart
- [ ] Gerar APK com `isProduction = true`
- [ ] Publicar na Play Store

---

## 🎉 Pronto!

Seu backend agora está rodando 24/7 no Railway com PostgreSQL incluído!

**URLs Importantes:**
- 🌐 Dashboard: https://railway.app
- 📚 Docs: https://docs.railway.app
- 💬 Discord: https://discord.gg/railway

---

## 🚀 Alternativa Rápida (cli)

Railway também suporta deploy via CLI:

```bash
# Instalar CLI
npm install -g @railway/cli

# Login
railway login

# Deploy
cd c:\ecommerce-app
railway up
```

Muito rápido e prático! 🎯
