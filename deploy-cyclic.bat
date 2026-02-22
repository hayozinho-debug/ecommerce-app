@echo off
REM 🚀 Script de Deploy Rápido para Cyclic (Windows)
REM Execute: deploy-cyclic.bat

echo 🔍 Verificando git...
git rev-parse --git-dir >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Este diretório não é um repositório git. Inicializando...
    git init
)

echo 📦 Adicionando arquivos...
git add .

echo 💬 Criando commit...
set /p commit_msg="Digite a mensagem do commit (ou pressione Enter para usar 'Deploy para Cyclic'): "
if "%commit_msg%"=="" set commit_msg=Deploy para Cyclic
git commit -m "%commit_msg%"

echo 🌐 Verificando remote...
git remote get-url origin >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ Nenhum remote configurado.
    set /p repo_url="Digite a URL do repositório GitHub: "
    git remote add origin "!repo_url!"
)

echo 🚀 Fazendo push para GitHub...
git push -u origin main

echo.
echo ✅ Código enviado para GitHub!
echo.
echo 📋 Próximos passos:
echo 1. Acesse: https://cyclic.sh
echo 2. Login com GitHub
echo 3. Clique em 'Link Your Own'
echo 4. Selecione seu repositório
echo 5. Configure as variáveis de ambiente
echo 6. Deploy! 🎉
echo.
echo 📚 Guia completo em: DEPLOY_CYCLIC.md
pause
