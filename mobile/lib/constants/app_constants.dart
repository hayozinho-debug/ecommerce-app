class ApiConstants {
  // ⚙️ CONFIGURAÇÃO DE AMBIENTE
  // Altere para 'true' quando for gerar o APK para produção
  static const bool isProduction = false;
  
  // URLs dos ambientes
  // 🔧 Após fazer deploy no Railway, atualize com a URL real (ex: https://ecommerce-api-prod-xxxx.up.railway.app/api)
  static const String _productionUrl = 'https://seu-app.up.railway.app/api';
  static const String _developmentUrl = 'http://192.168.5.4:3000/api';
  
  // URL base (alterna automaticamente baseado no ambiente)
  static String get apiUrl => isProduction ? _productionUrl : _developmentUrl;
  
  // Endpoints da API
  static String get authRegister => '$apiUrl/auth/register';
  static String get authLogin => '$apiUrl/auth/login';
  static String get authVerify => '$apiUrl/auth/verify';
  static String get products => '$apiUrl/products';
  static String get categories => '$apiUrl/categories';
  static String get shopifyProducts => '$apiUrl/shopify/products';
  static String get shopifyCollections => '$apiUrl/shopify/collections';
  static String get cart => '$apiUrl/cart';
  static String get orders => '$apiUrl/orders';
}

class AppConstants {
  static const String appName = 'Ecommerce Moda';
  static const String appVersion = '1.0.0';
  
  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String cartKey = 'cart_items';
}
