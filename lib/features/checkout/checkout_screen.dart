import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/shop_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';

/// Where it is going, and what it comes to.
///
/// No payment happens here — this screen only settles the address and shows
/// the figures, and the next one takes the money. Keeping them apart means
/// backing out of payment leaves the order unplaced rather than half-made.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShopProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shop = context.watch<ShopProvider>();
    final address = shop.selectedAddress;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(l10n.checkoutTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: shop.isCartEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 48, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(l10n.emptyCart,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: Text(l10n.discover),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.shippingAddress,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.addresses),
                      child: Text(address == null ? l10n.addAddress : l10n.modify),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (address == null)
                  _card(
                    theme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.noAddresses,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          // Said here rather than only failing at the end:
                          // place_order rejects an order with no address, and
                          // discovering that after tapping Pay is a bad way to
                          // find out.
                          'Add a delivery address before placing the order.',
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                      ],
                    ),
                  )
                else
                  ...shop.addresses.map((a) => _addressTile(a, shop, theme)),

                const SizedBox(height: 24),
                Text(l10n.summary,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                _card(
                  theme,
                  child: Column(
                    children: [
                      ...shop.cart.map((i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('${i.qty} × ${i.product.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                                Text('${formatXaf(i.lineTotalXaf)} FCFA',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          )),
                      Divider(color: theme.dividerColor),
                      _row(l10n.subtotal, '${shop.subtotalLabel} FCFA', theme),
                      const SizedBox(height: 6),
                      _row(l10n.delivery,
                          shop.deliveryXaf == 0 ? '—' : '${shop.deliveryLabel} FCFA', theme),
                      Divider(color: theme.dividerColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.orderTotal,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          Text('${shop.totalLabel} FCFA',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? AppColors.orange : AppColors.dark)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  // The number above is indicative until the server prices it.
                  // Saying so is cheaper than a surprise on the receipt.
                  'The final total is confirmed when the order is placed.',
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: address == null ? null : () => context.push(AppRoutes.payment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.orange : AppColors.dark,
                    foregroundColor: isDark ? AppColors.dark : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('Continuer vers paiement',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
    );
  }

  Widget _addressTile(Address a, ShopProvider shop, ThemeData theme) {
    final selected = shop.selectedAddress?.id == a.id;
    return GestureDetector(
      onTap: () => shop.selectAddress(a.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.orange : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? AppColors.orange : theme.hintColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.fullName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  Text(a.oneLine,
                      style: TextStyle(fontSize: 12, color: theme.hintColor)),
                  Text(a.phone, style: TextStyle(fontSize: 12, color: theme.hintColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(ThemeData theme, {required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: child,
      );

  Widget _row(String label, String value, ThemeData theme) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: theme.hintColor)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      );
}
