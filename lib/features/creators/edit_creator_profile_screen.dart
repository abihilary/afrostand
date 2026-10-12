import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../app/constants.dart';
import '../../shared/widgets/image_editor_screen.dart';

class EditCreatorProfileScreen extends StatefulWidget {
  const EditCreatorProfileScreen({super.key});

  @override
  State<EditCreatorProfileScreen> createState() => _EditCreatorProfileScreenState();
}

class _EditCreatorProfileScreenState extends State<EditCreatorProfileScreen> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _avatarUrlController = TextEditingController();
  bool _isLoading = false;
  File? _pickedAvatarFile;

  @override
  void initState() {
    super.initState();
    _storeNameController.text = 'MIDE Stores';
    _locationController.text = 'Dakar, Sénégal';
    _bioController.text = 'Créatrice de boubous modernes, fusion entre wax authentique et coupes contemporaines.';
    _avatarUrlController.text = AppAssets.model2;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        final editedFile = await Navigator.push<File>(
          context,
          MaterialPageRoute(
            builder: (context) => ImageEditorScreen(imageFile: File(pickedFile.path)),
          ),
        );
        if (editedFile != null) {
          setState(() {
            _pickedAvatarFile = editedFile;
            _avatarUrlController.text = editedFile.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick avatar: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creator profile updated successfully! ✨')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.dark),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Creator Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: _pickedAvatarFile != null
                              ? FileImage(_pickedAvatarFile!) as ImageProvider
                              : (_avatarUrlController.text.startsWith('http')
                                  ? NetworkImage(_avatarUrlController.text) as ImageProvider
                                  : FileImage(File(_avatarUrlController.text))),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: AppColors.orange, width: 2),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.dark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('OR ENTER AVATAR URL LINK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(
              controller: _avatarUrlController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'https://images.unsplash.com/...'),
            ),

            const SizedBox(height: 20),

            const Text('STORE / CREATOR NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(controller: _storeNameController),

            const SizedBox(height: 20),

            const Text('LOCATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(controller: _locationController),

            const SizedBox(height: 20),

            const Text('BIO / DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
                ),
            ),
          ],
        ),
      ),
    );
  }
}
