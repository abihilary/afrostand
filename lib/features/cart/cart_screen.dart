import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/shop_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/animated_pressable.dart';

/// The basket.
///
/// Held in `cart_items` rather than in memory, so it survives closing the app
/// and follows the account to another phone — which on a shared or borrowed
/// handset is the normal case here, not an edge one.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        context.read<ShopProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shop = context.watch<ShopProvider>();
    final signedIn = context.watch<AuthProvider>().isAuthenticated;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    AnimatedPressable(
                      onTap: () =>
                          context.canPop() ? context.pop() : context.go(AppRoutes.home),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            size: 20, color: isDark ? Colors.white : AppColors.dark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${l10n.panier} • ${shop.cartCount} ${l10n.items}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                if (shop.cart.isNotEmpty)
                  AnimatedPressable(
                    onTap: () => shop.clearCart(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        l10n.clear,
                        style: TextStyle(
                            color: isDark
                                ? AppColors.orange
                                : Colors.black.withValues(alpha: 0.4),
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _body(l10n, theme, isDark, shop, signedIn)),
        ],
      ),
    );
  }

  Widget _body(AppLocalizations l10n, ThemeData theme, bool isDark, ShopProvider shop,
      bool signedIn) {
    if (!signedIn) {
      return _empty(theme, Icons.lock_outline_rounded, l10n.signInToContinue, null,
          action: ElevatedButton(
            onPressed: () => context.push(AppRoutes.login),
            child: Text(l10n.signIn),
          ));
    }
    if (shop.isLoading && shop.cart.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (shop.hasError && shop.cart.isEmpty) {
      return _empty(theme, Icons.cloud_off_rounded, l10n.somethingWrong, l10n.checkConnection,
          action: OutlinedButton(onPressed: shop.load, child: Text(l10n.retry)));
    }
    if (shop.cart.isEmpty) {
      return _empty(theme, Icons.shopping_bag_outlined, l10n.emptyCart, l10n.emptyCartHint,
          action: ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text(l10n.discover),
          ));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        ...shop.cart.map((item) => _cartItem(item, shop)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    l10n.summary,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _summaryRow(l10n.subtotal, '${shop.subtotalLabel} FCFA'),
              const SizedBox(height: 8),
              // The server's figure, fetched from delivery_quote, not a second
              // copy of the rule here that could quote a price we then do not
              // honour at checkout.
              _summaryRow(
                l10n.delivery,
                shop.deliveryXaf == 0 ? '—' : '${shop.deliveryLabel} FCFA',
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.orderTotal,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  Text('${shop.totalLabel} FCFA',
                      style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => context.push(AppRoutes.checkout),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.orange : AppColors.dark,
            foregroundColor: isDark ? AppColors.dark : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: Text('${l10n.placeOrder} • ${shop.totalLabel} FCFA',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _empty(ThemeData theme, IconData icon, String title, String? hint,
      {Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: theme.hintColor)),
            ],
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }

  Widget _cartItem(CartItem item, ShopProvider shop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final variant = [item.size, item.color].where((s) => s.isNotEmpty).join(' • ');

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.orange),
      ),
      onDismissed: (_) => shop.removeFromCart(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.push(AppRoutes.productDetail(item.product.id)),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.dividerColor,
                  image: item.product.imageUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(item.product.imageUrl), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  Text(
                    variant.isEmpty ? item.product.creatorName : variant,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${formatXaf(item.lineTotalXaf)} FCFA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.orange : AppColors.dark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _qtyBtn(Icons.remove,
                                onTap: () => shop.setQty(item.id, item.qty - 1)),
                            const SizedBox(width: 12),
                            Text('${item.qty}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 12),
                            _qtyBtn(Icons.add, onTap: () => shop.setQty(item.id, item.qty + 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedPressable(
      onTap: onTap,
      scale: 0.8,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: isDark ? Colors.white : AppColors.dark),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
