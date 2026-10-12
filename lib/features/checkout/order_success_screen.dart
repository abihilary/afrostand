import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';

/// Confirmation, from the order that was actually written.
///
/// Used to print "Aminata", "AFR-2025-8821" and "22 000 FCFA" to everyone who
/// reached it, whatever they had bought. Now it reads `OrdersProvider.lastOrder`
/// — and if there is nothing to show, says so rather than inventing a receipt.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final order = context.watch<OrdersProvider>().lastOrder;
    final name = context.watch<ProfileProvider>().displayName;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.check_circle_rounded, size: 72, color: AppColors.orange)
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                l10n.orderConfirmed,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (order != null)
                Text(
                  '$name — ${order.code}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: theme.hintColor),
                ),
              const SizedBox(height: 28),
              if (order == null)
                Text(
                  l10n.nothingHere,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      ...order.items.map((i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('${i.name} ×${i.qty}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800, fontSize: 13)),
                                ),
                                Text('${formatXaf(i.lineTotalXaf)} FCFA',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                          )),
                      Divider(color: theme.dividerColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.orderTotal,
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${order.totalLabel} FCFA',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _statusLine(order, l10n),
                          style: TextStyle(fontSize: 11, color: theme.hintColor),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                // Goes to Orders, where the order actually is. It used to go
                // to the home screen, so "track order" lost the order.
                onPressed: () => context.go(AppRoutes.orders),
                child: Text(l10n.trackOrder),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l10n.continueShopping),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLine(Order order, AppLocalizations l10n) {
    final where = (order.shipTo['city'] ?? '').toString();
    final status = switch (order.status) {
      OrderStatus.paid => l10n.orderPlaced,
      OrderStatus.pending => l10n.paymentPending,
      OrderStatus.shipped => 'Expédiée',
      OrderStatus.delivered => 'Livrée',
      OrderStatus.cancelled => 'Annulée',
      OrderStatus.refunded => 'Remboursée',
    };
    return where.isEmpty ? status : '$status • $where';
  }
}
