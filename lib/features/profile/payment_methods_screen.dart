import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/shop_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_snack.dart';

/// Saved ways to pay.
///
/// Stores a label and a masked display string and nothing else. No card
/// numbers, no mobile money PINs — when a real provider is connected the
/// instrument lives with them, and this table only ever remembers which one
/// the customer prefers.
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShopProvider>().load();
    });
  }

  Future<void> _add() async {
    final shop = context.read<ShopProvider>();
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MethodSheet(shop: shop, l10n: l10n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shop = context.watch<ShopProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.profile)),
        title: Text(l10n.paymentMethods,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addPaymentMethod),
      ),
      body: shop.isLoading && shop.paymentMethods.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : shop.paymentMethods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.credit_card_off_outlined, size: 48, color: theme.hintColor),
                      const SizedBox(height: 16),
                      Text(l10n.noPaymentMethods,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                  itemCount: shop.paymentMethods.length,
                  itemBuilder: (context, i) {
                    final m = shop.paymentMethods[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: m.isDefault ? AppColors.orange : theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(_icon(m.kind), size: 22, color: theme.hintColor),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 14)),
                                if (m.masked != null)
                                  Text(m.masked!,
                                      style: TextStyle(
                                          fontSize: 12, color: theme.hintColor)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => shop.deletePaymentMethod(m.id),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  IconData _icon(PaymentKind k) => switch (k) {
        PaymentKind.card => Icons.credit_card_rounded,
        PaymentKind.cashOnDelivery => Icons.payments_outlined,
        PaymentKind.mobileMoney => Icons.phone_android_rounded,
      };
}

class _MethodSheet extends StatefulWidget {
  const _MethodSheet({required this.shop, required this.l10n});
  final ShopProvider shop;
  final AppLocalizations l10n;

  @override
  State<_MethodSheet> createState() => _MethodSheetState();
}

class _MethodSheetState extends State<_MethodSheet> {
  final _label = TextEditingController();
  final _masked = TextEditingController();
  PaymentKind _kind = PaymentKind.mobileMoney;
  bool _isDefault = false;
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    _masked.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      await widget.shop.savePaymentMethod(
        kind: _kind,
        label: _label.text.trim(),
        masked: _masked.text.trim().isEmpty ? null : _masked.text.trim(),
        isDefault: _isDefault,
      );
      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.addPaymentMethod,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 16),
          SegmentedButton<PaymentKind>(
            segments: [
              ButtonSegment(value: PaymentKind.mobileMoney, label: Text(l10n.mobileMoney)),
              ButtonSegment(value: PaymentKind.card, label: Text(l10n.bankCard)),
              ButtonSegment(
                  value: PaymentKind.cashOnDelivery, label: Text(l10n.cashOnDelivery)),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _label,
            decoration: const InputDecoration(
                labelText: 'Orange Money, MTN MoMo...', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _masked,
            decoration: const InputDecoration(
              // Explicitly the last digits, not the number. Nothing on this
              // screen should ever hold a full instrument.
              labelText: '•••• 1234',
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v),
            title: Text(l10n.setDefault, style: const TextStyle(fontSize: 13)),
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.saveLabel),
            ),
          ),
        ],
      ),
    );
  }
}
