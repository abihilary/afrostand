import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../generated/l10n/app_localizations.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> orders = [
      {'id': '#AF-8271', 'date': '12 Oct 2024', 'total': '18 500 FCFA', 'status': 'Delivered', 'items': 3},
      {'id': '#AF-7162', 'date': '04 Oct 2024', 'total': '12 000 FCFA', 'status': 'Shipped', 'items': 1},
      {'id': '#AF-6051', 'date': '28 Sep 2024', 'total': '45 000 FCFA', 'status': 'Processing', 'items': 5},
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.myOrders,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['id'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(order['date'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45)),
                      ],
                    ),
                    _statusBadge(order['status']),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order['items']} ${l10n.items}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      order['total'],
                      style: TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.orange : AppColors.dark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'Delivered':
        color = Colors.green;
        break;
      case 'Shipped':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
