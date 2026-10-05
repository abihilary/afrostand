import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../generated/l10n/app_localizations.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 3; // Default to card

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
          l10n.paymentTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : AppColors.sand,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalToPay,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '22 000',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isDark ? AppColors.orange : AppColors.dark),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'FCFA',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black.withOpacity(0.4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '2 ${l10n.items} • ${l10n.shipping} express incluse',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black.withOpacity(0.4), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text(
              l10n.mobileMoney,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.black45, letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            
            _paymentMethod(0, 'Wave', '#00A6FF', 'Paiement instantané'),
            const SizedBox(height: 12),
            _paymentMethod(1, 'Orange Money', '#FF7900', 'Le plus utilisé au Sénégal'),
            const SizedBox(height: 12),
            _paymentMethod(2, 'MTN MoMo', '#FFCC00', 'Paiement sécurisé'),

            const SizedBox(height: 32),
            Text(
              l10n.bankCard,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.black45, letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            
            GestureDetector(
              onTap: () => setState(() => _selectedMethod = 3),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedMethod == 3 ? (isDark ? AppColors.orange : AppColors.dark) : theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _selectedMethod == 3 ? Colors.transparent : theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.credit_card_rounded, color: Colors.black),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Carte Visa / Mastercard',
                            style: TextStyle(
                              color: _selectedMethod == 3 ? (isDark ? AppColors.dark : Colors.white) : (isDark ? Colors.white : AppColors.dark),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '•••• 4242 • Exp 12/27',
                            style: TextStyle(
                              color: _selectedMethod == 3 ? (isDark ? AppColors.dark.withOpacity(0.6) : Colors.white70) : (isDark ? Colors.white38 : Colors.black45),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedMethod == 3)
                      Icon(Icons.check_circle_rounded, color: isDark ? AppColors.dark : Colors.white, size: 20),
                  ],
                ),
              ),
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
          onPressed: () => context.go(AppRoutes.orderSuccess),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange, 
            foregroundColor: AppColors.dark,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.smartphone_rounded, size: 20),
              const SizedBox(width: 8),
              Text('${l10n.pay} 22 000 FCFA'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentMethod(int index, String name, String hexColor, String desc) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedMethod == index;
    final color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (isDark ? AppColors.orange : AppColors.dark) : theme.dividerColor, 
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                name[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  Text(desc, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.orange : (isDark ? Colors.white12 : Colors.black12), 
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
