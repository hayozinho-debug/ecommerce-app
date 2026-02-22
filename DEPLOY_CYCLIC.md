# 🚀 Deploy no Cyclic.sh - Guia Completo

## ✨ Por que Cyclic?
- ✅ **100% Gratuito** para começar
- ✅ **Não dorme** (sempre ativo)
- ✅ Deploy em **1 clique** via GitHub
- ✅ **Sem cartão de crédito**
- ✅ HTTPS automático
- ✅ 30s timeout (suficiente para e-commerce)

---

## 📋 Pré-requisitos
- ✅ Conta no GitHub
- ✅ Código commitado no GitHub
- ✅ Banco de dados PostgreSQL (Supabase)

---

## 🎯 Passo a Passo

### 1️⃣ Preparar o Repositório GitHub

```bash
# Se ainda não tem git iniciado
git init
git add .
git commit -m "Deploy para Cyclic"

# Criar repositório no GitHub e fazer push
git remote add origin https://github.com/SEU_USUARIO/ecommerce-app.git
git branch -M main
git push -u origin main
```

### 2️⃣ Criar Conta no Cyclic

1. Acesse: **https://cyclic.sh**
2. Clique em **"Login with GitHub"**
3. Autorize o Cyclic a acessar seus repositórios

### 3️⃣ Deploy do Projeto

1. No dashboard do Cyclic, clique em **"Link Your Own"**
2. Selecione o repositório **ecommerce-app**
3. Clique em **"Connect"**
4. O Cyclic detectará automaticamente que é um projeto Node.js
5. Clique em **"Deploy"**

### 4️⃣ Configurar Variáveis de Ambiente

Após o deploy inicial, clique em **"Variables"** e adicione:

```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://postgres:JUdas1478952@db.ldbfsljqeedfhxwdrnma.supabase.co:5432/postgres
JWT_SECRET=seu_jwt_secret_super_seguro_aqui
SHOPIFY_STORE_DOMAIN=brazlucca.myshopify.com
SHOPIFY_STOREFRONT_TOKEN=9b170957a5e834043ef1f0c0d449c180
SHOPIFY_API_VERSION=2024-10
```

**⚠️ Importante:** Clique em **"Save"** e depois em **"Redeploy"** para aplicar as variáveis.

### 5️⃣ Verificar a URL da API

Após o deploy, você receberá uma URL como:
```
https://seu-projeto-nome.cyclic.app
```

Sua API estará disponível em:
```
https://seu-projeto-nome.cyclic.app/api
```

### 6️⃣ Testar a API

Teste no navegador ou Postman:
```
https://seu-projeto-nome.cyclic.app/api/shopify/products
```

Você deve ver a lista de produtos em JSON.

---

## 📱 Atualizar o App Flutter

### Passo 1: Copiar a URL do Cyclic

No dashboard do Cyclic, copie a URL do seu app (algo como: `https://amazing-app-xyz.cyclic.app`)

### Passo 2: Atualizar app_constants.dart

Abra `mobile/lib/constants/app_constants.dart` e atualize:

```dart
static const String _productionUrl = 'https://SEU_APP.cyclic.app/api';
```

Substitua `SEU_APP.cyclic.app` pela URL real do Cyclic.

### Passo 3: Gerar o APK

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
```

---

## 🔄 Deploy Automático

O Cyclic faz **deploy automático** sempre que você fizer push no GitHub:

```bash
# Fazer alterações no código
git add .
git commit -m "Atualização do backend"
git push

# O Cyclic detecta e faz deploy automático! 🎉
```

---

## 🛠️ Comandos Úteis

### Ver Logs
No dashboard do Cyclic, clique em **"Logs"** para ver erros e informações.

### Reiniciar o App
Clique em **"Redeploy"** no dashboard.

### Configurar Domínio Customizado
1. Vá em **"Settings"**
2. Clique em **"Custom Domain"**
3. Adicione seu domínio (ex: `api.seusite.com`)

---

## 🐛 Solução de Problemas

### ❌ Build falhou

**Erro:** `Module not found` ou `Cannot find module`

**Solução:**
```bash
# Certifique-se de que todas as dependências estão no package.json
npm install
git add package.json package-lock.json
git commit -m "Atualizar dependências"
git push
```

### ❌ Prisma não inicializa

**Erro:** `PrismaClient is unable to run...`

**Solução:** Adicione no `package.json`:
```json
"scripts": {
  "postinstall": "prisma generate"
}
```

### ❌ Database connection failed

**Solução:** Verifique se a `DATABASE_URL` está correta nas variáveis de ambiente do Cyclic.

---

## 📊 Limites do Plano Gratuito

| Recurso | Limite |
|---------|--------|
| **Apps** | Ilimitados |
| **Requests** | Ilimitadas |
| **Bandwidth** | 100 GB/mês |
| **Build time** | 5 min |
| **Request timeout** | 30s |
| **Uptime** | 99.9% |

**✅ Perfeito para seu e-commerce!**

---

## 🎉 Pronto!

Seu backend agora está rodando 24/7 no Cyclic! 

**URLs Importantes:**
- 🌐 Dashboard: https://app.cyclic.sh
- 📚 Docs: https://docs.cyclic.sh
- 💬 Support: https://discord.gg/cyclic

---

## 🔐 Segurança

**⚠️ NUNCA commite secrets no GitHub!**

Use as variáveis de ambiente do Cyclic para:
- `DATABASE_URL`
- `JWT_SECRET`
- `SHOPIFY_STOREFRONT_TOKEN`

---

## 📈 Monitoramento

O Cyclic fornece:
- ✅ Logs em tempo real
- ✅ Métricas de requisições
- ✅ Alertas de erro
- ✅ Status do deploy

Acesse tudo no dashboard: **https://app.cyclic.sh**
