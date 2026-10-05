import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../generated/l10n/app_localizations.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, String>> _methods = [
    {'type': 'Visa', 'number': '•••• 4242', 'exp': '12/27'},
    {'type': 'Wave', 'number': '+221 77 ••• •• 67', 'exp': ''},
    {'type': 'Orange Money', 'number': '+221 78 ••• •• 10', 'exp': ''},
  ];

  void _showAddPayment() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddPaymentModal(onAdd: (method) {
        setState(() => _methods.add(method));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.payments,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _methods.length,
              itemBuilder: (context, index) {
                final method = _methods[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getColor(method['type']!),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          method['type']![0],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(method['type']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(method['number']!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45)),
                          ],
                        ),
                      ),
                      if (method['exp']!.isNotEmpty)
                        Text(method['exp']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.hintColor)),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ElevatedButton(
              onPressed: _showAddPayment,
              child: const Text('Add Payment Method'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String type) {
    if (type.contains('Visa')) return Colors.black;
    if (type.contains('Wave')) return const Color(0xFF00A6FF);
    if (type.contains('Orange')) return const Color(0xFFFF7900);
    return Colors.grey;
  }
}

class _AddPaymentModal extends StatelessWidget {
  final Function(Map<String, String>) onAdd;
  const _AddPaymentModal({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('New Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          const TextField(decoration: InputDecoration(hintText: 'Card Number or Mobile Number')),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: TextField(decoration: InputDecoration(hintText: 'Expiry (MM/YY)'))),
              const SizedBox(width: 16),
              const Expanded(child: TextField(decoration: InputDecoration(hintText: 'CVV'))),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              onAdd({
                'type': 'Visa',
                'number': '•••• 1234',
                'exp': '10/28',
              });
              context.pop();
            },
            child: const Text('Save Method'),
          ),
        ],
      ),
    );
  }
}
