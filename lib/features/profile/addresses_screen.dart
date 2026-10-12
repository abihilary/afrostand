import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/shop_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';

/// Delivery addresses.
///
/// Owner-scoped by RLS, so the list query carries no `user_id` filter — one
/// that the client added could be removed by patching the client, and a policy
/// cannot.
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShopProvider>().load();
    });
  }

  Future<void> _edit({Address? existing}) async {
    final shop = context.read<ShopProvider>();
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressSheet(existing: existing, shop: shop, l10n: l10n),
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
        title: Text(l10n.addresses,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addAddress),
      ),
      body: shop.isLoading && shop.addresses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : shop.addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_outlined, size: 48, color: theme.hintColor),
                      const SizedBox(height: 16),
                      Text(l10n.noAddresses,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                  itemCount: shop.addresses.length,
                  itemBuilder: (context, i) {
                    final a = shop.addresses[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: a.isDefault ? AppColors.orange : theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(a.fullName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800, fontSize: 14)),
                                    if (a.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.orange.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(l10n.setDefault,
                                            style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.orange)),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(a.oneLine,
                                    style:
                                        TextStyle(fontSize: 12, color: theme.hintColor)),
                                Text(a.phone,
                                    style:
                                        TextStyle(fontSize: 12, color: theme.hintColor)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _edit(existing: a),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                          ),
                          IconButton(
                            onPressed: () => shop.deleteAddress(a.id),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({this.existing, required this.shop, required this.l10n});
  final Address? existing;
  final ShopProvider shop;
  final AppLocalizations l10n;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  late final _name = TextEditingController(text: widget.existing?.fullName);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _line1 = TextEditingController(text: widget.existing?.line1);
  late final _city = TextEditingController(text: widget.existing?.city);
  late bool _isDefault = widget.existing?.isDefault ?? false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = widget.l10n;
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _line1.text.trim().isEmpty ||
        _city.text.trim().isEmpty) {
      setState(() => _error = l10n.somethingWrong);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      await widget.shop.saveAddress(
        id: widget.existing?.id,
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        line1: _line1.text.trim(),
        city: _city.text.trim(),
        isDefault: _isDefault,
      );
      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.existing == null ? l10n.addAddress : l10n.editAddress,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 16),
          _field(_name, l10n.fullNameLabel),
          _field(_phone, l10n.phoneLabel, keyboard: TextInputType.phone),
          _field(_line1, l10n.addressLine),
          _field(_city, l10n.cityLabel),
          SwitchListTile(
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v),
            title: Text(l10n.setDefault, style: const TextStyle(fontSize: 13)),
            contentPadding: EdgeInsets.zero,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.amber, fontSize: 12)),
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

  Widget _field(TextEditingController c, String label, {TextInputType? keyboard}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );
}
