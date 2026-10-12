import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../app/constants.dart';
import '../../core/providers/data_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/widgets/image_editor_screen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  bool _isNew = true;
  bool _isLoading = false;
  File? _pickedImageFile;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
            _pickedImageFile = editedFile;
            _imageUrlController.text = editedFile.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submitProduct() async {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final discount = _discountController.text.trim();

    if (name.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter product name and price')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final creatorName = auth.currentUser?.userMetadata?['full_name'] ?? 'MIDE Stores';

    final finalImageUrl = imageUrl.isNotEmpty ? imageUrl : AppAssets.model1;

    final dataProvider = context.read<DataProvider>();
    await dataProvider.addProduct(
      name: name,
      price: price,
      creator: creatorName,
      imageUrl: finalImageUrl,
      discount: discount.isNotEmpty ? discount : null,
      isNew: _isNew,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added successfully & persisted! 🥳')),
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
        title: const Text('Add New Product', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publish your creation to the Afrostand marketplace',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 24),

            // Image Picker / Preview with proper FileImage vs NetworkImage handling
            Center(
              child: InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                    image: _pickedImageFile != null
                        ? DecorationImage(image: FileImage(_pickedImageFile!), fit: BoxFit.cover)
                        : (_imageUrlController.text.isNotEmpty)
                            ? (_imageUrlController.text.startsWith('http')
                                ? DecorationImage(image: NetworkImage(_imageUrlController.text), fit: BoxFit.cover)
                                : DecorationImage(image: FileImage(File(_imageUrlController.text)), fit: BoxFit.cover))
                            : null,
                  ),
                  child: _pickedImageFile == null && _imageUrlController.text.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_rounded, size: 36, color: AppColors.orange),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to pick, resize & crop image',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.dark),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text('OR ENTER IMAGE URL LINK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(
              controller: _imageUrlController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'https://images.unsplash.com/...'),
            ),

            const SizedBox(height: 20),

            const Text('PRODUCT NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g., Boubou Wax Royal'),
            ),

            const SizedBox(height: 20),

            const Text('PRICE (FCFA)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g., 8500'),
            ),

            const SizedBox(height: 20),

            const Text('DISCOUNT (Optional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(
              controller: _discountController,
              decoration: const InputDecoration(hintText: 'e.g., -30%'),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Checkbox(
                  value: _isNew,
                  onChanged: (val) => setState(() => _isNew = val ?? true),
                  activeColor: AppColors.orange,
                ),
                const Text('Mark as NEW collection item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitProduct,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Publish Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
