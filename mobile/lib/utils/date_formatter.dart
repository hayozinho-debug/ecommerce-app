class DateFormatter {
  /// Formata a data no padrão brasileiro DD/MM/YYYY
  /// Aceita formatos: ISO 8601 (2024-01-15), brasileiro (15/01/2024), ou timestamp
  static String formatBrazilian(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }

    try {
      // Se já está no formato brasileiro DD/MM/YYYY, retorna como está
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dateString)) {
        return dateString;
      }

      // Tenta parsear como ISO 8601 (2024-01-15 ou 2024-01-15T00:00:00)
      DateTime? date;
      
      if (dateString.contains('T') || dateString.contains('-')) {
        date = DateTime.tryParse(dateString);
      }
      
      if (date != null) {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }

      // Se não conseguiu parsear, retorna a string original
      return dateString;
    } catch (e) {
      return dateString;
    }
  }
}
