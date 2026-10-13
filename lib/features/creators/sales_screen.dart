import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_snack.dart';

/// The seller's side of an order: what has been bought, and sending it.
///
/// Everything here is scoped to one shop's own lines. An order can hold goods
/// from several shops — `place_order()` prices the whole cart regardless of who
/// made what — so this screen never shows, totals or acts on a line belonging
/// to somebody else, and the SQL refuses it even if it tried.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String? _busyOrder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().load();
      context.read<OrdersProvider>().loadSales();
    });
  }

  Future<void> _run(String orderId, Future<int> Function() action, String whenNone) async {
    setState(() => _busyOrder = orderId);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final moved = await action();
      if (!mounted) return;
      // The count is the point. An UPDATE that matched nothing succeeds, and
      // "sent!" over an order with none of your goods left in it is a lie the
      // seller would only discover from an angry customer.
      messenger.showSnackBar(SnackBar(
        content: Text(moved == 0 ? whenNone : l10n.sentLines(moved)),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
    } finally {
      if (mounted) setState(() => _busyOrder = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final creator = context.watch<ProfileProvider>().myCreator;
    final ordersP = context.watch<OrdersProvider>();

    final mine = creator == null ? <Order>[] : ordersP.salesFor(creator.id);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.creatorDashboard),
        ),
        title: Text(l10n.salesTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ordersP.loadSales(),
        child: ordersP.isLoading && mine.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : mine.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(l10n.noSales,
                            style: TextStyle(color: theme.hintColor)),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: mine.length,
                    itemBuilder: (_, i) => _orderCard(mine[i], creator!, l10n, theme),
                  ),
      ),
    );
  }

  Widget _orderCard(Order o, Creator creator, AppLocalizations l10n, ThemeData theme) {
    final lines = o.linesFor(creator.id);
    final mineTotal = lines.fold(0, (s, i) => s + i.lineTotalXaf);
    final pending = lines.where((i) => i.fulfilment == Fulfilment.pending).length;
    final shipped = lines.where((i) => i.fulfilment == Fulfilment.shipped).length;
    final busy = _busyOrder == o.id;

    // Only a paid order is ready to leave the workshop, and a cancelled one is
    // not a dispatch instruction. Same rule as the SQL, so the button is
    // absent rather than present and rejected.
    final canAct = o.status == OrderStatus.paid || o.status == OrderStatus.shipped;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(o.code,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              const Spacer(),
              _chip(statusLabel(o.status, l10n), statusColor(o.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.yourLines,
              style: TextStyle(fontSize: 11, color: theme.hintColor)),
          const SizedBox(height: 10),
          ...lines.map((i) => _line(i, l10n, theme)),
          Divider(color: theme.dividerColor),
          Row(
            children: [
              // This shop's figure, never the order total: the rest of the
              // order may belong to somebody else entirely.
              Text('${formatXaf(mineTotal)} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const Spacer(),
              if (busy)
                const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else if (canAct && pending > 0)
                ElevatedButton(
                  onPressed: () => _askTracking(o),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.dark,
                  ),
                  child: Text(l10n.markShipped,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                )
              else if (canAct && shipped > 0)
                OutlinedButton(
                  onPressed: () => _run(
                    o.id,
                    () => context.read<OrdersProvider>().markDelivered(o.id),
                    l10n.nothingToSend,
                  ),
                  child: Text(l10n.markDelivered,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(OrderItem i, AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: theme.dividerColor,
              image: (i.imageUrl ?? '').isEmpty
                  ? null
                  : DecorationImage(image: NetworkImage(i.imageUrl!), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i.qty} × ${i.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                if ((i.trackingRef ?? '').isNotEmpty)
                  Text(l10n.trackingIs(i.trackingRef!),
                      style: TextStyle(fontSize: 10, color: theme.hintColor)),
              ],
            ),
          ),
          _chip(
            switch (i.fulfilment) {
              Fulfilment.pending => l10n.toShip,
              Fulfilment.shipped => l10n.statusShipped,
              Fulfilment.delivered => l10n.statusDelivered,
            },
            switch (i.fulfilment) {
              Fulfilment.pending => Colors.amber,
              Fulfilment.shipped => Colors.blue,
              Fulfilment.delivered => Colors.green,
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w900, color: color)),
      );

  /// The tracking reference is optional and asked for once, here, rather than
  /// being a field the seller has to find later.
  Future<void> _askTracking(Order o) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.markShipped),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.trackingOptional,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirm)),
        ],
      ),
    );
    if (send != true || !mounted) return;
    final tracking = controller.text.trim();
    await _run(
      o.id,
      () => context
          .read<OrdersProvider>()
          .markShipped(o.id, tracking: tracking.isEmpty ? null : tracking),
      l10n.nothingToSend,
    );
  }
}

/// Shared with the buyer's orders screen so one status cannot be called two
/// different things on two screens of the same app.
String statusLabel(OrderStatus s, AppLocalizations l10n) => switch (s) {
      OrderStatus.pending => l10n.statusPending,
      OrderStatus.paid => l10n.statusPaid,
      OrderStatus.shipped => l10n.statusShipped,
      OrderStatus.delivered => l10n.statusDelivered,
      OrderStatus.cancelled => l10n.statusCancelled,
      OrderStatus.refunded => l10n.statusRefunded,
    };

Color statusColor(OrderStatus s) => switch (s) {
      OrderStatus.pending => Colors.amber,
      OrderStatus.paid => AppColors.orange,
      OrderStatus.shipped => Colors.blue,
      OrderStatus.delivered => Colors.green,
      OrderStatus.cancelled => Colors.grey,
      OrderStatus.refunded => Colors.grey,
    };
