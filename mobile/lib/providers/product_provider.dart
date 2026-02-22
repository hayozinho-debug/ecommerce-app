import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import '../constants/app_constants.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  bool _isLoading = false;
  bool _isLoadingFeatured = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _featuredErrorMessage;
  String? _cursor;
  bool _hasNextPage = true;

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;
  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get featuredErrorMessage => _featuredErrorMessage;
  bool get hasNextPage => _hasNextPage;

  Future<void> fetchProducts({int? categoryId, int? first, String? sortKey, String? collectionGid}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _cursor = null;
      _hasNextPage = true;
      notifyListeners();

      // Se temos um collectionGid (para buscar por coleção específica)
      if (collectionGid != null && collectionGid.isNotEmpty) {
        final queryParams = <String, String>{
          'collectionGid': collectionGid,
        };
        if (first != null) {
          queryParams['first'] = first.toString();
        }
        if (sortKey != null) {
          queryParams['sortKey'] = sortKey;
        }

        Uri uri = Uri.parse('${ApiConstants.apiUrl}/shopify/collection-products');
        if (queryParams.isNotEmpty) {
          uri = uri.replace(queryParameters: queryParams);
        }

        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _products = (data['products'] as List)
              .map((p) => Product.fromJson(p))
              .toList();
          _cursor = data['pageInfo']?['endCursor'];
          _hasNextPage = data['pageInfo']?['hasNextPage'] ?? false;
        } else {
          _errorMessage = 'Erro ao buscar produtos';
        }
      } else {
        // Caso contrário, busca todos os produtos (com filtro opcional de categoria)
        final queryParams = <String, String>{};
        if (categoryId != null) {
          queryParams['query'] = 'collection_id:$categoryId';
        }
        if (first != null) {
          queryParams['first'] = first.toString();
        }
        if (sortKey != null) {
          queryParams['sortKey'] = sortKey;
        }

        Uri uri = Uri.parse(ApiConstants.shopifyProducts);
        if (queryParams.isNotEmpty) {
          uri = uri.replace(queryParameters: queryParams);
        }

        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _products = (data['products'] as List)
              .map((p) => Product.fromJson(p))
              .toList();
          _cursor = data['pageInfo']?['endCursor'];
          _hasNextPage = data['pageInfo']?['hasNextPage'] ?? false;
        } else {
          _errorMessage = 'Erro ao buscar produtos';
        }
      }
    } catch (e) {
      _errorMessage = 'Erro de conexão: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreProducts({int? categoryId, int? first, String? sortKey}) async {
    if (_isLoadingMore || !_hasNextPage) {
      return;
    }

    try {
      _isLoadingMore = true;
      notifyListeners();

      final queryParams = <String, String>{};
      if (categoryId != null) {
        queryParams['query'] = 'collection_id:$categoryId';
      }
      if (first != null) {
        queryParams['first'] = first.toString();
      }
      if (sortKey != null) {
        queryParams['sortKey'] = sortKey;
      }
      if (_cursor != null) {
        queryParams['after'] = _cursor!;
      }

      Uri uri = Uri.parse(ApiConstants.shopifyProducts);
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newProducts = (data['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList();
        _products.addAll(newProducts);
        _cursor = data['pageInfo']?['endCursor'];
        _hasNextPage = data['pageInfo']?['hasNextPage'] ?? false;
      }
    } catch (e) {
      _errorMessage = 'Erro de conexão: $e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeaturedProducts({int? first = 10, String? sortKey}) async {
    try {
      _isLoadingFeatured = true;
      _featuredErrorMessage = null;
      notifyListeners();

      final queryParams = <String, String>{};
      if (first != null) {
        queryParams['first'] = first.toString();
      }
      if (sortKey != null) {
        queryParams['sortKey'] = sortKey;
      }

      Uri uri = Uri.parse(ApiConstants.shopifyProducts);
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _featuredProducts = (data['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList();
      } else {
        _featuredErrorMessage = 'Erro ao buscar produtos';
      }
    } catch (e) {
      _featuredErrorMessage = 'Erro de conexão: $e';
    } finally {
      _isLoadingFeatured = false;
      notifyListeners();
    }
  }

  Product? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
