class PriceFormatter {
  /// Formata o preço no padrão brasileiro
  /// Exemplo: 1234.56 -> "1.234,56"
  static String format(double price) {
    // Separa parte inteira e decimal
    final parts = price.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    // Adiciona pontos como separador de milhares
    String formattedInteger = '';
    int count = 0;
    
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formattedInteger = '.$formattedInteger';
      }
      formattedInteger = integerPart[i] + formattedInteger;
      count++;
    }
    
    // Retorna com vírgula como separador decimal
    return '$formattedInteger,$decimalPart';
  }
  
  /// Formata o preço com o símbolo R$
  /// Exemplo: 1234.56 -> "R$ 1.234,56"
  static String formatWithCurrency(double price) {
    return 'R\$ ${format(price)}';
  }
}
