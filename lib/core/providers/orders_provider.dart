import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/repositories.dart';
import '../payments/payment_gateway.dart';
import '../../shared/models/models.dart';
import 'catalog_provider.dart' show Loadable;

/// Placing an order and everything after it.
///
/// Checkout is three steps and they are separate on purpose, because the
/// middle one can fail on its own: the order exists before the charge is
/// attempted, so a failed payment leaves a pending order somebody can retry or
/// cancel rather than a cart that silently emptied into nothing.
class OrdersProvider extends ChangeNotifier with Loadable {
  OrdersProvider({PaymentGateway? gateway}) : _gateway = gateway ?? StubPaymentGateway();

  final _repo = OrdersRepository();
  final PaymentGateway _gateway;

  List<Order> _orders = [];
  List<Order> _sales = [];
  Order? _lastOrder;

  List<Order> get orders => _orders;
  List<Order> get sales => _sales;

  /// The order the success screen shows. Held here rather than passed through
  /// the route so a reload of that screen does not lose it.
  Order? get lastOrder => _lastOrder;

  Future<void> load() => guard(() async {
        _orders = await _repo.orders();
      });

  Future<void> loadSales() => guard(() async {
        _sales = await _repo.salesForMyShop();
      });

  void clearLocal() {
    _orders = [];
    _sales = [];
    _lastOrder = null;
    notifyListeners();
  }

  /// Place, charge, settle.
  ///
  /// Returns the order either way. Read `order.status` to know what happened:
  /// `paid` if the charge went through, still `pending` if it did not. The
  /// method does not throw on a declined payment, because a decline is an
  /// ordinary outcome the checkout screen has to render, not an exception.
  Future<Order> checkout({
    required String addressId,
    int deliveryXaf = 0,
    String methodLabel = 'Mobile money',
  }) async {
    _loadingCheckout = true;
    notifyListeners();
    try {
      // 1. Postgres prices the cart and writes the order. Nothing about the
      //    total passes through this app.
      final orderId = await _repo.placeOrder(addressId: addressId, deliveryXaf: deliveryXaf);

      var order = await _repo.order(orderId);
      if (order == null) throw const PostgrestException(message: 'Order was placed but could not be read back');

      // 2. The provider. Fake today, Campay later, same call.
      final result = await _gateway.charge(
        orderId: orderId,
        amountXaf: order.totalXaf,
        methodLabel: methodLabel,
      );

      // 3. Record what the provider said. See settle_stub_payment's header in
      //    the schema for why this step moves to a webhook the day the gateway
      //    is real.
      if (result.isSuccess) {
        await Supabase.instance.client.rpc('settle_stub_payment', params: {
          'p_order_id': orderId,
          'p_reference': result.reference,
        });
        order = await _repo.order(orderId) ?? order;
      }

      _lastOrder = order;
      _orders = await _repo.orders();
      return order;
    } finally {
      _loadingCheckout = false;
      notifyListeners();
    }
  }

  bool _loadingCheckout = false;
  bool get isCheckingOut => _loadingCheckout;

  Future<void> cancel(String orderId) async {
    await Supabase.instance.client.rpc('cancel_my_order', params: {'p_order_id': orderId});
    _orders = await _repo.orders();
    notifyListeners();
  }
}
