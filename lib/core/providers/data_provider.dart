import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/product.dart';
import '../../app/constants.dart';

class DataProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<Product> _products = [];
  List<Map<String, dynamic>> _creators = [];
  List<Map<String, dynamic>> _categories = [];

  bool get isLoading => _isLoading;
  List<Product> get products => _products;
  List<Map<String, dynamic>> get creators => _creators;
  List<Map<String, dynamic>> get categories => _categories;

  DataProvider() {
    fetchData();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final productResponse = await _supabase.from('products').select();
      if (productResponse != null && (productResponse as List).isNotEmpty) {
        _products = productResponse.map((item) {
          return Product(
            name: item['name'] ?? 'Product',
            creator: item['creator'] ?? 'Creator',
            price: item['price']?.toString() ?? '5000',
            image: item['image_url'] ?? AppAssets.model1,
            discount: item['discount'],
            isNew: item['is_new'] ?? false,
          );
        }).toList();
      } else {
        _loadSampleStubProducts();
      }

      final creatorResponse = await _supabase.from('creators').select();
      if (creatorResponse != null && (creatorResponse as List).isNotEmpty) {
        _creators = List<Map<String, dynamic>>.from(creatorResponse);
      } else {
        _loadSampleStubCreators();
      }

      final catResponse = await _supabase.from('categories').select();
      if (catResponse != null && (catResponse as List).isNotEmpty) {
        _categories = List<Map<String, dynamic>>.from(catResponse);
      } else {
        _loadSampleStubCategories();
      }
    } catch (e) {
      _loadSampleStubProducts();
      _loadSampleStubCreators();
      _loadSampleStubCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct({
    required String name,
    required String price,
    required String creator,
    required String imageUrl,
    String? discount,
    bool isNew = false,
  }) async {
    try {
      await _supabase.from('products').insert({
        'name': name,
        'price': double.tryParse(price) ?? 5000,
        'creator': creator,
        'image_url': imageUrl,
        'discount': discount,
        'is_new': isNew,
      });
    } catch (e) {
      debugPrint('Supabase insert note: $e');
    }

    // Persist locally in state immediately
    _products.insert(
      0,
      Product(
        name: name,
        creator: creator,
        price: price,
        image: imageUrl.isNotEmpty ? imageUrl : AppAssets.model1,
        discount: discount,
        isNew: isNew,
      ),
    );
    notifyListeners();
    return true;
  }

  void removeProduct(int index) {
    if (index >= 0 && index < _products.length) {
      _products.removeAt(index);
      notifyListeners();
    }
  }

  void updateProduct(int index, Product updated) {
    if (index >= 0 && index < _products.length) {
      _products[index] = updated;
      notifyListeners();
    }
  }

  void _loadSampleStubProducts() {
    _products = [
      Product(name: '[SAMPLE] Boubou Wax Royal', creator: 'MIDE Stores', price: '8 000', image: AppAssets.model1, isNew: true),
      Product(name: '[SAMPLE] Ensemble Ankara', creator: 'Aïsha K.', price: '12 500', image: AppAssets.model3, discount: '-30%'),
      Product(name: '[SAMPLE] Tunique Kente', creator: 'Ghanart', price: '10 500', image: AppAssets.model4),
      Product(name: '[SAMPLE] Sac Raphia Tressé', creator: 'Atelier Dakar', price: '9 800', image: AppAssets.model5),
      Product(name: '[SAMPLE] Sandales Cuir Bio', creator: 'Maro Dakar', price: '7 400', image: AppAssets.model6, isNew: true),
      Product(name: '[SAMPLE] Boucles Cauri Gold', creator: 'Bijoux Baobab', price: '3 200', image: AppAssets.model2, isNew: true),
    ];
  }

  void _loadSampleStubCreators() {
    _creators = [
      {"id": 1, "name": "MIDE Stores [SAMPLE]", "location": "Dakar, Sénégal", "followers": "1.2k"},
      {"id": 2, "name": "Aïsha K. [SAMPLE]", "location": "Abidjan, Côte d'Ivoire", "followers": "980"},
    ];
  }

  void _loadSampleStubCategories() {
    _categories = [
      {"name": "Local [SAMPLE]", "image_url": AppAssets.model1},
      {"name": "Wax [SAMPLE]", "image_url": AppAssets.model2},
    ];
  }
}
