import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class RecentlyViewedProvider with ChangeNotifier {
  static const String _recentlyViewedKey = 'recently_viewed_products_v1';
  static const int _maxRecentlyViewed = 20;

  final List<Product> _products = [];

  RecentlyViewedProvider() {
    _loadRecentlyViewed();
  }

  List<Product> get products => List.unmodifiable(_products);

  Future<void> addProduct(Product product) async {
    // Remove if already exists
    _products.removeWhere((p) => p.id == product.id);
    
    // Add to beginning
    _products.insert(0, product);
    
    // Keep only max items
    if (_products.length > _maxRecentlyViewed) {
      _products.removeRange(_maxRecentlyViewed, _products.length);
    }

    notifyListeners();
    await _saveRecentlyViewed();
  }

  Future<void> _saveRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _products.map((product) => product.toJson()).toList();
    await prefs.setString(_recentlyViewedKey, jsonEncode(payload));
  }

  Future<void> _loadRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentlyViewedKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final parsed = jsonDecode(raw) as List<dynamic>;
      final restored = parsed.whereType<Map<String, dynamic>>().toList(growable: false);

      _products.clear();
      for (final item in restored) {
        final product = Product.fromJson(item);
        _products.add(product);
      }

      notifyListeners();
    } catch (_) {
      // Ignore malformed local cache
    }
  }

  Future<void> clearAll() async {
    _products.clear();
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentlyViewedKey);
  }
}
