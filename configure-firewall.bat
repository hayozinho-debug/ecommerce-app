@echo off
echo Configurando Firewall para permitir acesso na porta 3000...
netsh advfirewall firewall add rule name="Node.js Server - Port 3000" dir=in action=allow protocol=TCP localport=3000
echo.
echo Regra criada com sucesso!
echo.
echo Agora tente acessar do celular: http://192.168.5.4:3000/api/shopify/products
pause
