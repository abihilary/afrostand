import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/repositories.dart';
import '../../shared/models/models.dart';
import 'catalog_provider.dart' show Loadable;

/// Cart, wishlist, addresses and saved payment methods — everything that
/// belongs to one shopper.
///
/// All four are owner-scoped by RLS, so every read here returns only the
/// signed-in user's rows without a single `.eq('user_id', ...)` in the query.
/// That is deliberate: a filter the client adds can be removed by patching the
/// client, and a policy cannot.
class ShopProvider extends ChangeNotifier with Loadable {
  final _repo = ShopRepository();

  List<CartItem> _cart = [];
  List<Product> _wishlist = [];
  Set<String> _wishlistIds = {};
  List<Address> _addresses = [];
  List<PaymentMethod> _paymentMethods = [];

  List<CartItem> get cart => _cart;
  List<Product> get wishlist => _wishlist;
  List<Address> get addresses => _addresses;
  List<PaymentMethod> get paymentMethods => _paymentMethods;

  int get cartCount => _cart.fold(0, (s, i) => s + i.qty);
  int get subtotalXaf => _cart.fold(0, (s, i) => s + i.lineTotalXaf);
  String get subtotalLabel => formatXaf(subtotalXaf);
  bool get isCartEmpty => _cart.isEmpty;

  int _deliveryXaf = 0;

  /// What delivery will actually cost, asked of the same function the order is
  /// priced with. Not recomputed in Dart: two copies of the rule drift, and the
  /// one the customer sees would be the one that is wrong.
  int get deliveryXaf => _deliveryXaf;
  String get deliveryLabel => formatXaf(_deliveryXaf);
  int get totalXaf => subtotalXaf + _deliveryXaf;
  String get totalLabel => formatXaf(totalXaf);

  Future<void> _refreshDeliveryQuote() async {
    if (_cart.isEmpty) {
      _deliveryXaf = 0;
      return;
    }
    try {
      final res = await Supabase.instance.client
          .rpc('delivery_quote', params: {'p_subtotal_xaf': subtotalXaf});
      _deliveryXaf = (res as num).toInt();
    } catch (_) {
      // Leave the last known figure rather than showing a free delivery the
      // server is not going to honour.
    }
  }

  bool isWishlisted(String productId) => _wishlistIds.contains(productId);

  /// Counted from the id set, which load() fills on sign-in — not from the
  /// product list, which only loadWishlist() fills and only the wishlist
  /// screen calls. The profile read the list, so it showed 0 favourites until
  /// you opened the wishlist, at which point the number appeared out of
  /// nowhere.
  int get wishlistCount => _wishlistIds.length;

  String? _selectedAddressId;

  /// Carried between checkout and payment, which are two screens and one
  /// decision. Held here rather than passed as a route argument so that
  /// backing out of payment and returning does not lose the choice.
  Address? get selectedAddress {
    if (_addresses.isEmpty) return null;
    final id = _selectedAddressId;
    if (id == null) return defaultAddress;
    return _addresses.where((a) => a.id == id).firstOrNull ?? defaultAddress;
  }

  void selectAddress(String id) {
    _selectedAddressId = id;
    notifyListeners();
  }

  Address? get defaultAddress => _addresses.isEmpty
      ? null
      : _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);

  Future<void> load() => guard(() async {
        _cart = await _repo.cart();
        await _refreshDeliveryQuote();
        _wishlistIds = await _repo.wishlistIds();
        _addresses = await _repo.addresses();
        _paymentMethods = await _repo.paymentMethods();
      });

  Future<void> loadWishlist() => guard(() async {
        _wishlist = await _repo.wishlist();
        _wishlistIds = _wishlist.map((p) => p.id).toSet();
      });

  /// Signed out, or the account changed. Dropping the state matters: a cart
  /// left on screen after sign-out belongs to somebody who is no longer here.
  Future<void> clearCart() async {
    await _repo.clearCart();
    _cart = [];
    _deliveryXaf = 0;
    notifyListeners();
  }

  void clearLocal() {
    _cart = [];
    _deliveryXaf = 0;
    _wishlist = [];
    _wishlistIds = {};
    _addresses = [];
    _paymentMethods = [];
    notifyListeners();
  }

  Future<void> addToCart(Product p, {int qty = 1, String size = '', String color = ''}) async {
    await _repo.addToCart(p.id, qty: qty, size: size, color: color);
    _cart = await _repo.cart();
    await _refreshDeliveryQuote();
    notifyListeners();
  }

  Future<void> setQty(String cartItemId, int qty) async {
    // Optimistic, because a quantity stepper that waits for a round trip
    // before moving feels broken on a slow connection. Re-read afterwards so a
    // rejected write cannot leave a wrong number on screen.
    final i = _cart.indexWhere((c) => c.id == cartItemId);
    if (i != -1 && qty > 0) {
      final old = _cart[i];
      _cart[i] = CartItem(id: old.id, product: old.product, qty: qty, size: old.size, color: old.color);
      notifyListeners();
    }
    await _repo.setQty(cartItemId, qty);
    _cart = await _repo.cart();
    await _refreshDeliveryQuote();
    notifyListeners();
  }

  Future<void> removeFromCart(String cartItemId) async {
    _cart.removeWhere((c) => c.id == cartItemId);
    notifyListeners();
    await _repo.removeFromCart(cartItemId);
    _cart = await _repo.cart();
    await _refreshDeliveryQuote();
    notifyListeners();
  }

  Future<void> toggleWishlist(String productId) async {
    final on = !_wishlistIds.contains(productId);
    on ? _wishlistIds.add(productId) : _wishlistIds.remove(productId);
    notifyListeners();
    try {
      await _repo.toggleWishlist(productId, on);
    } catch (e) {
      on ? _wishlistIds.remove(productId) : _wishlistIds.add(productId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveAddress({
    String? id,
    String? label,
    required String fullName,
    required String phone,
    required String line1,
    String? line2,
    required String city,
    bool isDefault = false,
  }) async {
    await _repo.saveAddress(
      id: id,
      label: label,
      fullName: fullName,
      phone: phone,
      line1: line1,
      line2: line2,
      city: city,
      isDefault: isDefault,
    );
    _addresses = await _repo.addresses();
    notifyListeners();
  }

  Future<void> deleteAddress(String id) async {
    await _repo.deleteAddress(id);
    _addresses = await _repo.addresses();
    notifyListeners();
  }

  Future<void> savePaymentMethod({
    required PaymentKind kind,
    required String label,
    String? masked,
    bool isDefault = false,
  }) async {
    await _repo.savePaymentMethod(kind: kind, label: label, masked: masked, isDefault: isDefault);
    _paymentMethods = await _repo.paymentMethods();
    notifyListeners();
  }

  Future<void> deletePaymentMethod(String id) async {
    await _repo.deletePaymentMethod(id);
    _paymentMethods = await _repo.paymentMethods();
    notifyListeners();
  }
}
