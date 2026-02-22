import 'package:flutter/material.dart';
import '../models/product.dart';

/// Retorna um mapa de nome da cor (original) para Color (Flutter)
Map<String, Color> getProductColorMap(Product product) {
  final variants = product.variants ?? [];
  final colorMap = <String, Color>{};

  for (final variant in variants) {
    final color = variant.color;
    if (color != null && color.trim().isNotEmpty) {
      final colorKey = color.trim().toUpperCase();
      if (!colorMap.containsKey(colorKey)) {
        colorMap[colorKey] = colorFromName(colorKey);
      }
    }
  }

  if (colorMap.isEmpty) {
    return {'DEFAULT': const Color(0xFFE0E0E0)};
  }

  return colorMap;
}

Color colorFromName(String name) {
  if (name.contains('PRETO')) return const Color(0xFF1F2937);
  if (name.contains('BRANCO')) return const Color(0xFFFFFFFF);
  if (name.contains('AZUL')) return const Color(0xFF2563EB);
  if (name.contains('VERDE')) return const Color(0xFF10B981);
  if (name.contains('VERMELHO')) return const Color(0xFFEF4444);
  if (name.contains('ROSA') || name.contains('PINK')) return const Color(0xFFF472B6);
  if (name.contains('LILAS') || name.contains('ROXO')) return const Color(0xFF8B5CF6);
  if (name.contains('AMARELO')) return const Color(0xFFF59E0B);
  if (name.contains('BEGE') || name.contains('CREME')) return const Color(0xFFF5DEB3);
  if (name.contains('CINZA') || name.contains('MESCLA')) return const Color(0xFF9CA3AF);
  if (name.contains('MARINHO')) return const Color(0xFF0F172A);
  return const Color(0xFFE0E0E0);
}

List<Color> getProductColors(Product product) {
  final variants = product.variants ?? [];
  final uniqueColors = <String>{};
  for (final variant in variants) {
    final color = variant.color;
    if (color != null && color.trim().isNotEmpty) {
      uniqueColors.add(color.trim().toUpperCase());
    }
  }

  if (uniqueColors.isEmpty) {
    return [const Color(0xFFE0E0E0)];
  }

  return uniqueColors.map(colorFromName).toList();
}
