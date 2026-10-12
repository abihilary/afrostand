import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../core/api/storage.dart';
import '../../core/providers/profile_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/widgets/image_editor_screen.dart';

/// Shop settings.
///
/// Same upload fix as the product form: the avatar and banner used to be
/// stored as local file paths, so a shop's own branding was invisible to
/// everybody except the person who set it.
class EditCreatorProfileScreen extends StatefulWidget {
  const EditCreatorProfileScreen({super.key});

  @override
  State<EditCreatorProfileScreen> createState() => _EditCreatorProfileScreenState();
}

class _EditCreatorProfileScreenState extends State<EditCreatorProfileScreen> {
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _bio = TextEditingController();

  File? _avatar;
  File? _banner;
  bool _busy = false;
  String? _error;
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final c = context.read<ProfileProvider>().myCreator;
    if (c != null) {
      _name.text = c.name;
      _location.text = c.location ?? '';
      _bio.text = c.bio ?? '';
      _seeded = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isAvatar) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final edited = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => ImageEditorScreen(imageFile: File(file.path))),
    );
    if (!mounted) return;
    setState(() {
      if (isAvatar) {
        _avatar = edited ?? File(file.path);
      } else {
        _banner = edited ?? File(file.path);
      }
    });
  }

  Future<void> _save() async {
    final profile = context.read<ProfileProvider>();
    final router = GoRouter.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String? avatarUrl;
      String? bannerUrl;
      if (_avatar != null) {
        avatarUrl = await uploadImage(_avatar!, bucket: StorageBuckets.avatars);
      }
      if (_banner != null) {
        bannerUrl = await uploadImage(_banner!, bucket: StorageBuckets.avatars);
      }
      await profile.updateShop(
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        location: _location.text.trim(),
        bio: _bio.text.trim(),
        avatarUrl: avatarUrl,
        bannerUrl: bannerUrl,
      );
      if (!mounted) return;
      router.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final creator = context.watch<ProfileProvider>().myCreator;

    if (creator == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: Center(child: Text(l10n.nothingHere)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(onPressed: _busy ? null : () => context.pop()),
        title: Text(l10n.myShop,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: _busy ? null : () => _pick(false),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor),
                image: _banner != null
                    ? DecorationImage(image: FileImage(_banner!), fit: BoxFit.cover)
                    : creator.bannerUrl != null
                        ? DecorationImage(
                            image: NetworkImage(creator.bannerUrl!), fit: BoxFit.cover)
                        : null,
              ),
              child: (_banner == null && creator.bannerUrl == null)
                  ? Center(
                      child: Text('Bannière',
                          style: TextStyle(color: theme.hintColor, fontSize: 12)))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: _busy ? null : () => _pick(true),
                child: CircleAvatar(
                  radius: 34,
                  backgroundImage: _avatar != null
                      ? FileImage(_avatar!)
                      : creator.avatarUrl != null
                          ? NetworkImage(creator.avatarUrl!) as ImageProvider
                          : null,
                  child: (_avatar == null && creator.avatarUrl == null)
                      ? const Icon(Icons.add_a_photo_outlined, size: 20)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Touchez pour changer les images',
                    style: TextStyle(fontSize: 12, color: theme.hintColor)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            enabled: !_busy,
            decoration: const InputDecoration(
                labelText: 'Nom de la boutique', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            enabled: !_busy,
            decoration: const InputDecoration(
                labelText: 'Ville, pays', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bio,
            enabled: !_busy,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
                labelText: 'À propos', border: OutlineInputBorder()),
          ),
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
            onPressed: _busy ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.dark,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _busy
                ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.saveLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
