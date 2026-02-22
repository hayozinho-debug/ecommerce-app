# Ecommerce Moda - Full Stack App

Aplicação de ecommerce para venda de roupas e moda, construída com **Node.js + TypeScript**, **Prisma**, **PostgreSQL**, e **React + Vite**.

## 🚀 Stack Tecnológico

- **Backend**: Node.js, Express, TypeScript, Prisma ORM
- **Banco de Dados**: PostgreSQL
- **Autenticação**: JWT
- **Frontend**: React 18, React Router, Vite, Axios
- **Containerização**: Docker Compose

## 📋 Requisitos

- Node.js v18+ e npm
- Docker e Docker Compose
- Git

## 🔧 Quick Start

### 1. Configure o arquivo `.env`

Crie um arquivo `.env` na raiz com:

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/ecommerce?schema=public
JWT_SECRET=change_this_jwt_secret_key_here
PORT=3000
```

### 2. Suba o PostgreSQL via Docker

```bash
docker-compose up -d
```

### 3. Configuração do backend

```bash
npm install
npx prisma generate
npx prisma migrate dev --name init
npm run dev
```

Servidor estará em: **http://localhost:3000**

### 4. Configuração do frontend

```bash
cd client
npm install
npm run dev
```

Frontend estará em: **http://localhost:5173**

---

## 📚 API Endpoints

### Autenticação (Public)
- `POST /api/auth/register` - Registrar usuário
- `POST /api/auth/login` - Login (retorna JWT)
- `POST /api/auth/verify` - Verificar token

### Produtos (Public Read)
- `GET /api/products` - Listar todos os produtos
- `GET /api/products?categoryId=1` - Filtrar por categoria
- `GET /api/products/:id` - Obter produto por ID

### Categorias (Public Read)
- `GET /api/categories` - Listar categorias
- `GET /api/categories/:id` - Obter categoria com produtos

### Carrinho (Autenticado)
- `POST /api/cart` - Adicionar item
- `GET /api/cart` - Obter carrinho
- `PUT /api/cart/:id` - Atualizar quantidade
- `DELETE /api/cart/:id` - Remover item

### Pedidos (Autenticado)
- `POST /api/orders` - Criar pedido
- `GET /api/orders` - Listar pedidos do usuário
- `GET /api/orders/:id` - Detalhes do pedido

### Admin (Admin only)
- `POST /api/products` - Criar produto
- `PUT /api/products/:id` - Atualizar produto
- `DELETE /api/products/:id` - Deletar produto
- `GET /api/admin/orders` - Listar todos os pedidos
- `PUT /api/admin/orders/:id/status` - Atualizar status

---

## 🧪 Teste Rápido

**Login de teste (após seed):**
- Email: `user@example.com`
- Senha: `password123`

**Admin (após seed):**
- Email: `admin@example.com`
- Senha: `password123`

---

## 📁 Estrutura

```
ecommerce-app/
├── src/
│   ├── controllers/
│   ├── services/
│   ├── routes/
│   ├── middlewares/
│   ├── db/
│   └── server.ts
├── prisma/
│   ├── schema.prisma
│   └── seed.ts
├── client/                # Frontend React + Vite
├── uploads/               # Static files
├── docker-compose.yml
├── .env.example
└── README.md
```

---

## 🔧 Comandos Úteis

```bash
# Backend
npm run dev              # Desenvolvimento
npm run migrate          # Rodar migrações
npm run seed             # Seed do banco
npx prisma studio       # GUI do banco

# Frontend
cd client && npm run dev # Desenvolvimento
cd client && npm run build # Build
```

---

## 🐳 Docker

Suba o banco de dados:
```bash
docker-compose up -d
```

Parar:
```bash
docker-compose down
```

Acessar pgAdmin em http://localhost:8080 (admin@admin.local / admin)

---

## 📊 Modelo de Dados

- **User**: Usuários (email, username, password, role)
- **Category**: Categorias de produtos
- **Product**: Produtos (title, description, price, images)
- **ProductVariant**: Variantes (tamanho, cor, estoque)
- **Order**: Pedidos
- **OrderItem**: Items dos pedidos
- **CartItem**: Items do carrinho

---

## 🔐 Autenticação

Sistema usa **JWT (JSON Web Tokens)**.

Roles:
- `user`: Usuário comum (pode comprar)
- `admin`: Pode gerenciar produtos

Fluxo:
1. Registrar/Login → retorna token JWT
2. Armazenar token em `localStorage`
3. Incluir `Authorization: Bearer <token>` em requisições autenticadas

---

## 📝 Features Implementadas

✅ Autenticação com JWT
✅ Gerenciamento de produtos (CRUD)
✅ Categorias de produtos
✅ Carrinho de compras
✅ Pedidos
✅ Painel Admin
✅ Frontend React com Vite
✅ Banco de dados PostgreSQL
✅ Seed com dados de moda

---

## � Deploy em Produção

### Deploy no Railway (Recomendado ⭐)

Railway oferece **$5/mês grátis**, PostgreSQL incluído, sem sleep mode e altamente estável.

📚 **[Guia Completo de Deploy](DEPLOY_RAILWAY.md)**

**Checklist Rápido:**
1. ✅ Push do código para GitHub
2. ✅ Criar conta no [Railway.app](https://railway.app)
3. ✅ Conectar repositório
4. ✅ Adicionar PostgreSQL (automático)
5. ✅ Configurar variáveis de ambiente
6. ✅ Deploy automático!

📋 **[Checklist Completo](CHECKLIST_DEPLOY.md)**

**Outras opções de deploy:**
- 🟠 Cyclic.sh - [Ver guia](DEPLOY_CYCLIC.md) (100% grátis, mais limitado)
- 🔷 Render.com - [Ver guia](DEPLOY.md)
- 🪂 Fly.io

---

## �🚦 Próximos Passos

- [ ] Upload de imagens
- [ ] Integração com Stripe/PayPal
- [ ] Testes automatizados
- [ ] Ci/CD

---

## 📄 Licença

MIT

---

## 📞 Suporte

- 📧 Email: desenvolvimento@seudominio.com
- 💬 WhatsApp: +55 47 3460-0332
- 🐛 Issues: GitHub Issues

---

**Desenvolvido com ❤️ para Ecommerce Moda**