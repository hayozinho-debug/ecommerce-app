# ✅ Checklist - Deploy no Cyclic

Use este checklist para garantir que tudo está configurado corretamente.

---

## 📋 Antes de Fazer Deploy

- [ ] Código testado localmente (backend rodando sem erros)
- [ ] Banco de dados Supabase configurado e funcionando
- [ ] Variáveis de ambiente anotadas (DATABASE_URL, JWT_SECRET, etc.)
- [ ] Código commitado no GitHub
- [ ] Conta criada no Cyclic.sh

---

## 🚀 Durante o Deploy

- [ ] Repositório conectado no Cyclic
- [ ] Variáveis de ambiente configuradas no dashboard
- [ ] Build completo com sucesso
- [ ] Deploy finalizado (status verde)
- [ ] URL da aplicação copiada (ex: https://seu-app.cyclic.app)

---

## ✨ Testes Após Deploy

- [ ] API responde: `https://seu-app.cyclic.app/api/shopify/products`
- [ ] Retorna JSON com produtos (não erro 500 ou 404)
- [ ] Autenticação funciona (testar login/registro no Postman)
- [ ] Carrinho e pedidos funcionando

---

## 📱 Atualizar App Mobile

- [ ] Abrir `mobile/lib/constants/app_constants.dart`
- [ ] Atualizar `_productionUrl` com a URL do Cyclic
- [ ] Alterar `isProduction = true`
- [ ] Executar `flutter clean && flutter pub get`
- [ ] Executar `flutter build apk --release`
- [ ] Testar APK em dispositivo real
- [ ] **IMPORTANTE:** Voltar `isProduction = false` após build

---

## 🔐 Segurança

- [ ] Arquivo `.env` NÃO commitado (verificar .gitignore)
- [ ] `JWT_SECRET` forte e único
- [ ] DATABASE_URL não exposta publicamente
- [ ] HTTPS ativo (Cyclic faz isso automaticamente)

---

## 📊 Monitoramento

- [ ] Logs do Cyclic verificados (sem erros)
- [ ] Métricas de requisições funcionando
- [ ] Acessar: https://app.cyclic.sh para ver dashboard

---

## 🎉 Deploy Completo!

Se todos os itens estão marcados, seu app está PRONTO para produção! 🚀

### URLs Úteis:
- 🌐 **Dashboard Cyclic:** https://app.cyclic.sh
- 📚 **Documentação:** https://docs.cyclic.sh
- 💾 **Supabase:** https://supabase.com/dashboard
- 🛍️ **Shopify:** https://brazlucca.myshopify.com/admin

---

## 🆘 Problemas?

Consulte o arquivo [DEPLOY_CYCLIC.md](DEPLOY_CYCLIC.md) seção "Solução de Problemas"
