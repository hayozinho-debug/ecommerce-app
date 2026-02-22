#!/bin/bash

# 🚀 Script de Deploy Rápido para Cyclic
# Execute: chmod +x deploy-cyclic.sh && ./deploy-cyclic.sh

echo "🔍 Verificando git..."
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Este diretório não é um repositório git. Inicializando..."
    git init
fi

echo "📦 Adicionando arquivos..."
git add .

echo "💬 Criando commit..."
read -p "Digite a mensagem do commit (ou pressione Enter para usar 'Deploy para Cyclic'): " commit_msg
commit_msg=${commit_msg:-"Deploy para Cyclic"}
git commit -m "$commit_msg"

echo "🌐 Verificando remote..."
if ! git remote get-url origin > /dev/null 2>&1; then
    echo "⚠️ Nenhum remote configurado."
    read -p "Digite a URL do repositório GitHub: " repo_url
    git remote add origin "$repo_url"
fi

echo "🚀 Fazendo push para GitHub..."
git push -u origin main

echo ""
echo "✅ Código enviado para GitHub!"
echo ""
echo "📋 Próximos passos:"
echo "1. Acesse: https://cyclic.sh"
echo "2. Login com GitHub"
echo "3. Clique em 'Link Your Own'"
echo "4. Selecione seu repositório"
echo "5. Configure as variáveis de ambiente"
echo "6. Deploy! 🎉"
echo ""
echo "📚 Guia completo em: DEPLOY_CYCLIC.md"
