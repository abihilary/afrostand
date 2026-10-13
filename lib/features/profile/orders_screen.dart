import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/orders_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_snack.dart';
import '../creators/sales_screen.dart' show statusLabel, statusColor;

/// Past and current orders.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrdersProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final orders = context.watch<OrdersProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.profile)),
        title: Text(l10n.orders,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: orders.load,
        child: orders.isLoading && orders.orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : orders.orders.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 140),
                      Icon(Icons.receipt_long_outlined, size: 48, color: theme.hintColor),
                      const SizedBox(height: 16),
                      Center(
                          child: Text(orders.hasError ? l10n.somethingWrong : l10n.emptyOrders,
                              style: const TextStyle(fontWeight: FontWeight.w700))),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.home),
                          child: Text(l10n.discover),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: orders.orders.length,
                    itemBuilder: (context, i) => _orderCard(orders.orders[i], orders, l10n, theme),
                  ),
      ),
    );
  }

  Widget _orderCard(Order o, OrdersProvider orders, AppLocalizations l10n, ThemeData theme) {
    final (label, color) = _status(o.status, l10n);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.code,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          if (o.createdAt != null)
            Text(
              '${o.createdAt!.day}/${o.createdAt!.month}/${o.createdAt!.year}',
              style: TextStyle(fontSize: 11, color: theme.hintColor),
            ),
          const SizedBox(height: 12),
          ...o.items.take(3).map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    if (i.imageUrl != null)
                      Container(
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                              image: NetworkImage(i.imageUrl!), fit: BoxFit.cover),
                        ),
                      ),
                    Expanded(
                      child: Text('${i.name} ×${i.qty}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Text('${formatXaf(i.lineTotalXaf)} FCFA',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              )),
          if (o.items.length > 3)
            Text('+${o.items.length - 3}',
                style: TextStyle(fontSize: 11, color: theme.hintColor)),
          Divider(color: theme.dividerColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.orderTotal,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              Text('${o.totalLabel} FCFA',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
          // Cancellable only while it can still be stopped. The SQL enforces
          // the same thing, so a stale screen cannot cancel a delivered order.
          if (o.status == OrderStatus.pending || o.status == OrderStatus.paid) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  try {
                    await orders.cancel(o.id);
                  } catch (e) {
                    if (!mounted) return;
                    showError(context, e);
                  }
                },
                child: Text(l10n.cancelOrder),
              ),
            ),
          ],
          // Receipt is the buyer's to confirm once something has actually been
          // posted. The seller can close their own lines too, for the buyer
          // who never comes back — but asking first is the better order.
          if (o.status == OrderStatus.shipped) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final n = await orders.confirmDelivery(o.id);
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(
                      content: Text(n == 0 ? l10n.nothingToConfirm : l10n.receiptConfirmed),
                      behavior: SnackBarBehavior.floating,
                    ));
                  } catch (e) {
                    if (!mounted) return;
                    showError(context, e);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.dark,
                ),
                child: Text(l10n.confirmReceipt,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Was six hardcoded French labels, three of which existed nowhere else in
  // the app, in a project with two locales. Shared with the seller's screen so
  // one status cannot be called two different things.
  (String, Color) _status(OrderStatus s, AppLocalizations l10n) =>
      (statusLabel(s, l10n).toUpperCase(), statusColor(s));
}
