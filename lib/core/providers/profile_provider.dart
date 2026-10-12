import 'package:flutter/foundation.dart';
import '../api/repositories.dart';
import '../../shared/models/models.dart';
import 'catalog_provider.dart' show Loadable;

/// Who the signed-in person is, and whether they have a shop.
class ProfileProvider extends ChangeNotifier with Loadable {
  final _repo = ProfileRepository();

  Profile? _me;
  Creator? _myCreator;
  List<Product> _myProducts = [];

  Profile? get me => _me;
  Creator? get myCreator => _myCreator;
  List<Product> get myProducts => _myProducts;

  String get displayName => _me?.fullName?.trim().isNotEmpty == true ? _me!.fullName! : 'Invité';
  CreatorStatus get creatorStatus => _me?.creatorStatus ?? CreatorStatus.none;

  /// Approved *and* actually holding a shop row. Both are required: approval
  /// without a creator row means the shop has not been created yet, and the
  /// dashboard has nothing to show.
  bool get canSell => _me?.isApprovedCreator == true && _myCreator != null;

  Future<void> load() => guard(() async {
        _me = await _repo.me();
        _myCreator = await _repo.myCreator();
        if (_myCreator != null) {
          _myProducts = await CatalogRepository().productsByCreator(_myCreator!.id);
        }
      });

  void clearLocal() {
    _me = null;
    _myCreator = null;
    _myProducts = [];
    notifyListeners();
  }

  Future<void> updateMe({String? fullName, String? phone, String? avatarUrl}) async {
    await _repo.updateMe(fullName: fullName, phone: phone, avatarUrl: avatarUrl);
    _me = await _repo.me();
    notifyListeners();
  }

  /// Mirror the chosen theme and language onto the account, so they follow the
  /// person to another device. Best-effort: a signed-out user still gets the
  /// setting locally, and a failed write must never block a theme toggle.
  Future<void> syncPreferences({String? locale, String? theme}) async {
    if (_me == null) return;
    try {
      await _repo.updateMe(locale: locale, theme: theme);
    } catch (_) {
      // Local preference already applied; nothing the user can act on.
    }
  }

  Future<void> requestCreatorStatus() async {
    await _repo.requestCreatorStatus();
    _me = await _repo.me();
    notifyListeners();
  }

  Future<void> updateShop({String? name, String? location, String? bio, String? avatarUrl, String? bannerUrl}) async {
    final c = _myCreator;
    if (c == null) return;
    await _repo.updateMyCreator(
      id: c.id,
      name: name,
      location: location,
      bio: bio,
      avatarUrl: avatarUrl,
      bannerUrl: bannerUrl,
    );
    _myCreator = await _repo.myCreator();
    notifyListeners();
  }

  Future<Product> addProduct({
    required String name,
    required int priceXaf,
    required String imageUrl,
    String? description,
    int? discountPct,
    List<String> tags = const [],
    String? categoryId,
  }) async {
    final c = _myCreator;
    if (c == null) throw StateError('No shop to list under');
    final p = await _repo.createProduct(
      creatorId: c.id,
      name: name,
      priceXaf: priceXaf,
      imageUrl: imageUrl,
      description: description,
      discountPct: discountPct,
      tags: tags,
      categoryId: categoryId,
    );
    _myProducts = [p, ..._myProducts];
    notifyListeners();
    return p;
  }

  Future<void> delistProduct(String id) async {
    await _repo.delistProduct(id);
    _myProducts = _myProducts.where((p) => p.id != id).toList();
    notifyListeners();
  }
}
