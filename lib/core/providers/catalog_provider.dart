import 'package:flutter/foundation.dart';
import '../api/repositories.dart';
import '../../shared/models/models.dart';

/// Shared loading/error bookkeeping.
///
/// The provider it replaces caught every exception and quietly swapped in
/// `[SAMPLE]` products. That is a dangerous shape for a shop: a customer can
/// put a sample in a basket, and the person who built it never sees the outage
/// because the screen still looks right. A failure has to be visible, so these
/// providers keep the error and the screens render it.
mixin Loadable on ChangeNotifier {
  bool _loading = false;
  Object? _error;

  bool get isLoading => _loading;
  Object? get error => _error;
  bool get hasError => _error != null;

  Future<void> guard(Future<void> Function() body) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await body();
    } catch (e) {
      _error = e;
      if (kDebugMode) debugPrint('$runtimeType: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

class CatalogProvider extends ChangeNotifier with Loadable {
  final _repo = CatalogRepository();

  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  List<Creator> _creators = [];

  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  List<Creator> get creators => _creators;

  /// Nothing came back and nothing went wrong — an empty catalogue, which is a
  /// different screen from a failed one and must not be shown as the same.
  bool get isEmpty => !isLoading && !hasError && _products.isEmpty;

  Future<void> load() => guard(() async {
        // Fetched together rather than in sequence - three round trips in a row
        // is three times the latency on a slow connection, and the home screen
        // needs all three before it can render anything.
        final products = _repo.products();
        final categories = _repo.categories();
        final creators = _repo.creators();
        _products = await products;
        _categories = await categories;
        _creators = await creators;
      });

  Future<List<Product>> byCategorySlug(String slug) => _repo.byCategorySlug(slug);
  Future<List<Product>> search(String term) => _repo.search(term);
  Future<Product?> product(String id) => _repo.product(id);
  Future<Creator?> creator(String id) => _repo.creator(id);
  Future<List<Product>> productsByCreator(String id) => _repo.productsByCreator(id);

  /// Products carrying a tag, from what is already loaded. The home screen
  /// filters between four collections on every tap, and a round trip for a
  /// filter the client can already answer would make it feel slow for nothing.
  List<Product> taggedLocally(String tag) {
    final t = tag.toLowerCase();
    return _products.where((p) => p.tags.any((x) => x.toLowerCase() == t)).toList();
  }
}
