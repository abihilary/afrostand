import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../generated/l10n/app_localizations.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedDelivery = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.checkoutTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.orange, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n.shippingAddress,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          l10n.modify,
                          style: const TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aminata Diallo\nVilla 12, Almadies, Dakar\n+221 77 123 45 67',
                    style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text(
              l10n.deliveryOptions,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            
            _deliveryOption(
              index: 0,
              title: 'Express 24h — Dakar',
              price: '1 500 FCFA',
              time: 'Demain, 14h',
            ),
            const SizedBox(height: 12),
            _deliveryOption(
              index: 1,
              title: 'Standard 2-3j — Sénégal',
              price: '2 500 FCFA',
              time: 'Lun 14 Avr',
            ),
            const SizedBox(height: 12),
            _deliveryOption(
              index: 2,
              title: 'Retrait boutique MIDE',
              price: 'Gratuit',
              time: "Aujourd'hui 17h",
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: ElevatedButton(
          onPressed: () => context.push(AppRoutes.payment),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.orange : AppColors.dark,
            foregroundColor: isDark ? AppColors.dark : Colors.white,
          ),
          child: const Text('Continuer vers paiement'),
        ),
      ),
    );
  }

  Widget _deliveryOption({
    required int index,
    required String title,
    required String price,
    required String time,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedDelivery == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedDelivery = index),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? AppColors.orange : AppColors.dark) : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : theme.dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? (isDark ? AppColors.dark : Colors.white) : (isDark ? Colors.white : AppColors.dark),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: isSelected ? (isDark ? AppColors.dark.withOpacity(0.7) : Colors.white70) : (isDark ? Colors.white38 : Colors.black45),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              price,
              style: TextStyle(
                color: isSelected ? (isDark ? AppColors.dark : Colors.white) : (isDark ? AppColors.orange : AppColors.dark),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
