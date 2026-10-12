import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/shop_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';

/// Taking the money — or, for now, pretending to.
///
/// The gateway behind this is `StubPaymentGateway`. Everything else on the
/// path is real: the order is written by `place_order()` at the catalogue's
/// prices before any charge is attempted, so a failed payment leaves a pending
/// order the buyer can retry or cancel rather than a cart that emptied into
/// nothing.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0;
  String? _failure;

  static const _methods = [
    ('Orange Money', Icons.phone_android_rounded),
    ('MTN MoMo', Icons.phone_android_rounded),
    ('Wave', Icons.account_balance_wallet_outlined),
    ('Carte bancaire', Icons.credit_card_rounded),
  ];

  Future<void> _pay() async {
    final shop = context.read<ShopProvider>();
    final orders = context.read<OrdersProvider>();
    final address = shop.selectedAddress;
    final router = GoRouter.of(context);

    if (address == null) {
      setState(() => _failure = 'Choose a delivery address first.');
      return;
    }

    setState(() => _failure = null);
    try {
      final order = await orders.checkout(
        addressId: address.id,
        methodLabel: _methods[_selectedMethod].$1,
      );
      if (!mounted) return;
      // The cart was emptied inside place_order; mirror that locally so the
      // badge does not keep showing items that are now an order.
      await shop.load();
      if (!mounted) return;

      if (order.status == OrderStatus.paid) {
        router.go(AppRoutes.orderSuccess);
      } else {
        // The order exists and is pending. Say so plainly and send them to
        // Orders, where it can be paid or cancelled — losing track of a
        // half-finished order is worse than the failed payment.
        setState(() => _failure = AppLocalizations.of(context)!.paymentPendingHint);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _failure = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shop = context.watch<ShopProvider>();
    final orders = context.watch<OrdersProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(onPressed: orders.isCheckingOut ? null : () => context.pop()),
        title: Text(l10n.paymentTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.totalToPay,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('${shop.totalLabel} FCFA',
                    style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  '${shop.cartCount} ${l10n.items} • ${l10n.delivery} ${shop.deliveryXaf == 0 ? "offerte" : "${shop.deliveryLabel} FCFA"}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.mobileMoney,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (var i = 0; i < _methods.length; i++) _methodTile(i, theme, isDark),

          // Not hidden behind a sandbox flag the tester has to know about. If
          // the screen is going to take a fake payment, it has to say so.
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, size: 16, color: AppColors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No payment provider is connected yet. The order is real; the charge is simulated.',
                    style: TextStyle(fontSize: 11, color: theme.hintColor, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          if (_failure != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_failure!, style: const TextStyle(fontSize: 12))),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.orders),
                    child: Text(l10n.orders),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: orders.isCheckingOut || shop.isCartEmpty ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.orange : AppColors.dark,
              foregroundColor: isDark ? AppColors.dark : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: orders.isCheckingOut
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('${l10n.placeOrder} • ${shop.totalLabel} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _methodTile(int i, ThemeData theme, bool isDark) {
    final selected = _selectedMethod == i;
    final (label, icon) = _methods[i];
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? (isDark ? AppColors.orange : AppColors.dark) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.transparent : theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? (isDark ? AppColors.dark : Colors.white)
                    : theme.hintColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected
                    ? (isDark ? AppColors.dark : Colors.white)
                    : (isDark ? Colors.white : AppColors.dark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
