import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class FavoriteEntry {
  final String key;
  final Product product;
  final String? selectedColor;
  final String? coverImageUrl;

  const FavoriteEntry({
    required this.key,
    required this.product,
    this.selectedColor,
    this.coverImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'selectedColor': selectedColor,
      'coverImageUrl': coverImageUrl,
      'product': product.toJson(),
    };
  }

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    return FavoriteEntry(
      key: json['key']?.toString() ?? '',
      selectedColor: json['selectedColor']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      product: productJson is Map<String, dynamic>
          ? Product.fromJson(productJson)
          : Product.fromJson(json),
    );
  }
}

class FavoritesProvider with ChangeNotifier {
  static const String _favoritesKey = 'favorite_products_v1';

  final Map<String, FavoriteEntry> _favoritesByKey = <String, FavoriteEntry>{};

  FavoritesProvider() {
    _loadFavorites();
  }

  List<FavoriteEntry> get items => _favoritesByKey.values.toList(growable: false);

  bool isFavorite({
    required Product product,
    String? selectedColor,
    String? coverImageUrl,
  }) {
    final key = buildFavoriteKey(
      product: product,
      selectedColor: selectedColor,
      coverImageUrl: coverImageUrl,
    );
    return _favoritesByKey.containsKey(key);
  }

  String buildFavoriteKey({
    required Product product,
    String? selectedColor,
    String? coverImageUrl,
  }) {
    final colorPart = (selectedColor ?? '').trim().toUpperCase();
    final coverPart = _normalizeImageUrl(coverImageUrl ?? '');
    return '${product.id}::$colorPart::$coverPart';
  }

  Future<void> toggleFavorite({
    required Product product,
    String? selectedColor,
    String? coverImageUrl,
  }) async {
    final key = buildFavoriteKey(
      product: product,
      selectedColor: selectedColor,
      coverImageUrl: coverImageUrl,
    );

    if (_favoritesByKey.containsKey(key)) {
      _favoritesByKey.remove(key);
    } else {
      _favoritesByKey[key] = FavoriteEntry(
        key: key,
        product: product,
        selectedColor: selectedColor,
        coverImageUrl: coverImageUrl,
      );
    }

    notifyListeners();
    await _saveFavorites();
  }

  Future<void> removeFavorite(String key) async {
    if (_favoritesByKey.remove(key) != null) {
      notifyListeners();
      await _saveFavorites();
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _favoritesByKey.values.map((entry) => entry.toJson()).toList();
    await prefs.setString(_favoritesKey, jsonEncode(payload));
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final parsed = jsonDecode(raw) as List<dynamic>;
      final restored = parsed.whereType<Map<String, dynamic>>().toList(growable: false);

      for (final item in restored) {
        if (item.containsKey('product') || item.containsKey('key')) {
          final entry = FavoriteEntry.fromJson(item);
          if (entry.key.isNotEmpty) {
            _favoritesByKey[entry.key] = entry;
            continue;
          }
        }

        final product = Product.fromJson(item);
        final coverImageUrl = product.images.isNotEmpty ? product.images.first.url : null;
        final key = buildFavoriteKey(
          product: product,
          coverImageUrl: coverImageUrl,
        );
        _favoritesByKey[key] = FavoriteEntry(
          key: key,
          product: product,
          coverImageUrl: coverImageUrl,
        );
      }

      notifyListeners();
    } catch (_) {
      // Ignore malformed local cache
    }
  }

  String _normalizeImageUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return url.trim().toLowerCase();

    final normalized = parsed.replace(query: null, fragment: null).toString();
    return normalized.trim().toLowerCase();
  }
}
