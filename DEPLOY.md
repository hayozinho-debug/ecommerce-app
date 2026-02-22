# Deploy no Render.com - Guia Passo a Passo

## 📋 Pré-requisitos
- Conta no GitHub
- Conta no Render.com (gratuita)
- Código do projeto commitado no GitHub

## 🚀 Passos para Deploy

### 1. Preparar o Repositório GitHub

```bash
# Inicializar git (se ainda não fez)
git init

# Adicionar todos os arquivos
git add .

# Fazer commit
git commit -m "Preparar projeto para deploy no Render"

# Criar repositório no GitHub e adicionar remote
git remote add origin https://github.com/SEU_USUARIO/ecommerce-app.git

# Push para o GitHub
git push -u origin main
```

### 2. Criar Conta no Render.com

1. Acesse: https://render.com
2. Clique em **"Get Started"**
3. Faça login com sua conta do GitHub

### 3. Criar Web Service

1. No Dashboard do Render, clique em **"New +"**
2. Selecione **"Web Service"**
3. Conecte seu repositório GitHub
4. Configure:
   - **Name:** `ecommerce-api` (ou o nome que preferir)
   - **Region:** Oregon (ou mais próximo)
   - **Branch:** `main`
   - **Root Directory:** deixe em branco
   - **Runtime:** `Node`
   - **Build Command:** 
     ```
     npm install && npm run build && npx prisma generate && npx prisma migrate deploy
     ```
   - **Start Command:** 
     ```
     npm start
     ```
   - **Plan:** Free

### 4. Configurar Variáveis de Ambiente

Na seção **Environment Variables**, adicione:

| Key | Value |
|-----|-------|
| `NODE_ENV` | `production` |
| `PORT` | `3000` |
| `DATABASE_URL` | `postgresql://postgres:JUdas1478952@db.ldbfsljqeedfhxwdrnma.supabase.co:5432/postgres` |
| `JWT_SECRET` | `change_this_jwt_secret` (ou gere um novo) |
| `SHOPIFY_STORE_DOMAIN` | `brazlucca.myshopify.com` |
| `SHOPIFY_STOREFRONT_TOKEN` | `9b170957a5e834043ef1f0c0d449c180` |
| `SHOPIFY_API_VERSION` | `2024-10` |

### 5. Deploy

1. Clique em **"Create Web Service"**
2. Aguarde o deploy (5-10 minutos)
3. Quando terminar, você receberá uma URL tipo: `https://ecommerce-api.onrender.com`

### 6. Testar a API

Acesse no navegador:
```
https://sua-url.onrender.com/api/shopify/products
```

### 7. Atualizar o App Flutter

No arquivo `mobile/lib/constants/app_constants.dart`:

```dart
class ApiConstants {
  static const String apiUrl = 'https://sua-url.onrender.com/api';
  // ... resto do código
}
```

Depois reconstrua o APK:
```bash
cd mobile
flutter build apk --release
```

## ⚠️ Importante

- **Plano Gratuito:** O app "dorme" após 15 minutos de inatividade
- **Primeiro Acesso:** Pode demorar ~1 minuto para "acordar"
- **Logs:** Acesse os logs pelo dashboard do Render
- **HTTPS:** Automático e configurado pelo Render

## 🔄 Atualizações Futuras

Toda vez que você fizer push para o GitHub na branch `main`, o Render fará deploy automático!

```bash
git add .
git commit -m "Minha atualização"
git push
```

## 📞 Suporte

- Documentação: https://render.com/docs
- Status: https://status.render.com
