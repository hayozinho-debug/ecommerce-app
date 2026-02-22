import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';
import '../constants/app_constants.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalPrice => 
      _items.fold(0, (sum, item) => sum + item.subtotal);

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(AppConstants.cartKey);
      if (cartJson != null) {
        final data = jsonDecode(cartJson) as List;
        // Filter out items with zero or invalid price to clean corrupted data
        _items = data
            .map((item) => CartItem.fromJson(item))
            .where((item) => item.productPrice > 0 && item.productTitle.isNotEmpty)
            .toList();
        // Save the cleaned cart
        await _saveCart();
        notifyListeners();
      }
    } catch (e) {
      // Error loading cart - clear everything
      _items.clear();
      await _saveCart();
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(AppConstants.cartKey, cartJson);
    } catch (e) {
      // Error saving cart
    }
  }

  void addItem(
    int productId,
    String productTitle,
    double productPrice, {
    int? variantId,
    List<String>? images,
    String? selectedColor,
    String? selectedSize,
  }) {
    final existingItemIndex = _items.indexWhere(
      (item) => item.productId == productId && item.variantId == variantId,
    );

    if (existingItemIndex >= 0) {
      _items[existingItemIndex].quantity++;
    } else {
      _items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: productId,
        productTitle: productTitle,
        productPrice: productPrice,
        variantId: variantId,
        images: images ?? [],
        selectedColor: selectedColor,
        selectedSize: selectedSize,
        quantity: 1,
      ));
    }

    _saveCart();
    notifyListeners();
  }

  void removeItem(int id) {
    _items.removeWhere((item) => item.id == id);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(int id, int quantity) {
    final item = _items.firstWhere((item) => item.id == id);
    if (quantity <= 0) {
      removeItem(id);
    } else {
      item.quantity = quantity;
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  Future<String> createShopifyCheckout() async {
    try {
      final lines = _items.map((item) => {
        'merchandiseId': 'gid://shopify/ProductVariant/${item.variantId ?? item.productId}',
        'quantity': item.quantity,
      }).toList();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiUrl}/shopify/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lines': lines}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['checkoutUrl'] as String;
      } else {
        throw Exception('Erro ao criar checkout: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao criar checkout: $e');
    }
  }
}
