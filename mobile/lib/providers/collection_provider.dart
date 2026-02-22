import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/collection.dart';
import '../constants/app_constants.dart';

class CollectionProvider with ChangeNotifier {
  List<Collection> _storiesCollections = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Collection> get storiesCollections => _storiesCollections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStoriesCollections() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConstants.apiUrl}/shopify/stories-collections');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> collectionsJson = data['collections'] ?? [];
        
        _storiesCollections = collectionsJson
            .map((json) => Collection.fromJson(json))
            .toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Erro ao carregar coleções: ${response.statusCode}';
      }
    } catch (error) {
      _errorMessage = 'Erro de conexão: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
