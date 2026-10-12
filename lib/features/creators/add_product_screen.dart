import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../core/api/storage.dart';
import '../../core/providers/catalog_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/image_editor_screen.dart';
import '../../shared/widgets/app_snack.dart';

/// List something for sale.
///
/// Three things were wrong here and all three mattered:
///
///   * The image was saved as `pickedFile.path` — a path inside this app's
///     cache. The product looked right on the phone that listed it and was a
///     broken image for every single customer. It now uploads to Storage and
///     stores the returned public URL.
///   * The shop was `user_metadata['full_name']`, defaulting to the string
///     'MIDE Stores' — so an unnamed seller's goods were attributed to
///     somebody else's shop. It is now the creator row the account owns, and
///     if there is not one, this screen says so rather than guessing.
///   * It reported "persisted! 🥳" whether or not the insert succeeded, because
///     the error was caught and logged. A failed listing now fails visibly.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _discount = TextEditingController();

  File? _picked;
  bool _busy = false;
  String? _status;
  String? _error;
  String? _categoryId;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _discount.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final edited = await Navigator.push<File?>(
        context,
        MaterialPageRoute(builder: (_) => ImageEditorScreen(imageFile: File(file.path))),
      );
      if (!mounted) return;
      setState(() => _picked = edited ?? File(file.path));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = humanError(e, AppLocalizations.of(context)!));
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.read<ProfileProvider>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final name = _name.text.trim();
    final priceText = _price.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(priceText);

    if (name.isEmpty || price == null || price <= 0) {
      setState(() => _error = 'Enter a name and a price in FCFA.');
      return;
    }
    if (_picked == null) {
      setState(() => _error = 'Add a photo of the item.');
      return;
    }
    if (profile.myCreator == null) {
      setState(() => _error = 'Your shop is not set up yet.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _status = l10n.uploadingImage;
    });

    try {
      // Upload first. A product row pointing at an image that failed to upload
      // is worse than no product row: it is a listing with a broken picture
      // that the seller has no obvious way to fix.
      final imageUrl = await uploadImage(_picked!);
      if (!mounted) return;
      setState(() => _status = l10n.saveLabel);

      final discountText = _discount.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      await profile.addProduct(
        name: name,
        priceXaf: price,
        imageUrl: imageUrl,
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        discountPct: discountText.isEmpty ? null : int.tryParse(discountText),
        categoryId: _categoryId,
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Article mis en ligne.')));
      router.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = humanError(e, l10n);
        _busy = false;
        _status = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = context.watch<ProfileProvider>();
    final categories = context.watch<CatalogProvider>().categories;

    if (!profile.canSell) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined, size: 48, color: theme.hintColor),
                const SizedBox(height: 16),
                Text(
                  switch (profile.creatorStatus) {
                    CreatorStatus.requested => l10n.creatorRequested,
                    CreatorStatus.rejected => l10n.creatorRejected,
                    _ => l10n.becomeCreator,
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(onPressed: _busy ? null : () => context.pop()),
        title: const Text('Nouvel article',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: _busy ? null : _pickImage,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
                image: _picked == null
                    ? null
                    : DecorationImage(image: FileImage(_picked!), fit: BoxFit.cover),
              ),
              child: _picked != null
                  ? null
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 32, color: theme.hintColor),
                        const SizedBox(height: 10),
                        Text('Ajouter une photo',
                            style: TextStyle(color: theme.hintColor, fontSize: 13)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            enabled: !_busy,
            decoration: InputDecoration(
                labelText: l10n.productName, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: l10n.priceLabel, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            enabled: !_busy,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
                labelText: l10n.description, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _discount,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Remise %', border: OutlineInputBorder()),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _categoryId,
              decoration: InputDecoration(
                  labelText: l10n.categories, border: const OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                ...categories.map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: _busy ? null : (v) => setState(() => _categoryId = v),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: const TextStyle(fontSize: 12)),
            ),
          ],
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.dark,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _busy
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                          height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text(_status ?? ''),
                    ],
                  )
                : Text(l10n.saveLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
