import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/widgets/animated_pressable.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Mock cart data
  final Map<int, int> _itemCounts = {
    0: 1, // Boubou Wax Royal
    1: 1, // Ensemble Ankara
  };

  final List<Map<String, dynamic>> _items = [
    {
      'id': 0,
      'name': 'Boubou Wax Royal',
      'desc': 'MIDE Stores • M • Orange',
      'price': 8000,
      'image': AppAssets.model1,
    },
    {
      'id': 1,
      'name': 'Ensemble Ankara',
      'desc': 'Aïsha K. • S • Yellow',
      'price': 12500,
      'image': AppAssets.model3,
    }
  ];

  int get _subtotal {
    int total = 0;
    for (var item in _items) {
      total += (item['price'] as int) * (_itemCounts[item['id']] ?? 0);
    }
    return total;
  }

  int get _total => _subtotal + 1500; // 1500 for shipping

  void _increment(int id) {
    setState(() {
      _itemCounts[id] = (_itemCounts[id] ?? 0) + 1;
    });
  }

  void _decrement(int id) {
    if ((_itemCounts[id] ?? 0) > 1) {
      setState(() {
        _itemCounts[id] = (_itemCounts[id] ?? 0) - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    AnimatedPressable(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.home);
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Icon(Icons.arrow_back_rounded, size: 20, color: isDark ? Colors.white : AppColors.dark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${l10n.panier} • ${_itemCounts.length} ${l10n.items}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                AnimatedPressable(
                  onTap: () => setState(() => _itemCounts.clear()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      l10n.clear,
                      style: TextStyle(color: isDark ? AppColors.orange : Colors.black.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ..._items.where((item) => _itemCounts.containsKey(item['id'])).map((item) {
                  return _cartItem(
                    item['id'],
                    item['name'],
                    item['desc'],
                    item['price'].toString(),
                    item['image'],
                  );
                }),
                
                if (_itemCounts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  
                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : AppColors.dark,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.summary,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _summaryRow(l10n.subtotal, '$_subtotal FCFA'),
                        const SizedBox(height: 12),
                        _summaryRow(l10n.shipping, '1 500 FCFA'),
                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '$_total FCFA',
                              style: TextStyle(
                                color: isDark ? AppColors.orange : Colors.white, 
                                fontSize: 18, 
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Text(
                        "Your cart is empty",
                        style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Bottom Action
          if (_itemCounts.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: AnimatedPressable(
                onTap: () => context.push(AppRoutes.checkout),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.orange : AppColors.dark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${l10n.placeOrder} • $_total FCFA',
                    style: TextStyle(
                      color: isDark ? AppColors.dark : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cartItem(int id, String name, String desc, String price, String url) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black.withOpacity(0.4), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$price FCFA',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.orange : AppColors.dark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          _qtyBtn(Icons.remove, onTap: () => _decrement(id)),
                          const SizedBox(width: 12),
                          Text('${_itemCounts[id]}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 12),
                          _qtyBtn(Icons.add, onTap: () => _increment(id)),
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
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
