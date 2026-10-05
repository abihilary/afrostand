import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../generated/l10n/app_localizations.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final List<Map<String, String>> _addresses = [
    {
      'type': 'Home',
      'address': 'Villa 12, Almadies, Dakar',
      'phone': '+221 77 123 45 67',
    },
    {
      'type': 'Office',
      'address': 'Immeuble SDI, Plateau, Dakar',
      'phone': '+221 33 821 10 10',
    },
  ];

  void _showAddAddress() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddAddressModal(onAdd: (addr) {
        setState(() => _addresses.add(addr));
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
          l10n.addresses,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final addr = _addresses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          addr['type'] == 'Home' ? Icons.home_filled : Icons.business_rounded,
                          color: AppColors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(addr['type']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(addr['address']!, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
                            const SizedBox(height: 4),
                            Text(addr['phone']!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ElevatedButton(
              onPressed: _showAddAddress,
              child: const Text('Add New Address'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAddressModal extends StatelessWidget {
  final Function(Map<String, String>) onAdd;
  const _AddAddressModal({required this.onAdd});

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
          const Text('New Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          const TextField(decoration: InputDecoration(hintText: 'Address Name (e.g. Home)')),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(hintText: 'Street, Villa, Apartment')),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(hintText: 'Phone Number')),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              onAdd({
                'type': 'New Location',
                'address': 'Dakar, Sénégal',
                'phone': '+221 70 000 00 00',
              });
              context.pop();
            },
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }
}
