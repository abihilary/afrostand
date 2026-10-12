import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/data_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/models/product.dart';

class CreatorDashboardScreen extends StatelessWidget {
  const CreatorDashboardScreen({super.key});

  void _showEditProductDialog(BuildContext context, Product product, int index) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price);
    final dataProvider = context.read<DataProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
            const SizedBox(height: 12),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (FCFA)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final updated = Product(
                name: nameController.text.trim(),
                creator: product.creator,
                price: priceController.text.trim(),
                image: product.image,
                discount: product.discount,
                isNew: product.isNew,
              );
              dataProvider.updateProduct(index, updated);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product updated successfully! ✨')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showProductOptions(BuildContext context, Product product, int index) {
    final dataProvider = context.read<DataProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('${product.price} FCFA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.orange)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.preview_rounded, color: AppColors.orange),
              title: const Text('Preview Item', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.home}/${AppRoutes.productDetail}', extra: product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showEditProductDialog(context, product, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Take Down (Delete)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              onTap: () {
                dataProvider.removeProduct(index);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product taken down from catalog.')),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dataProvider = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final storeName = auth.currentUser?.userMetadata?['full_name'] ?? 'MIDE Stores';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.dark),
          onPressed: () => context.pop(),
        ),
        title: Text('Creator Studio • $storeName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.editCreatorProfile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.dark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Earnings (This Month)',
                        style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.trending_up_rounded, color: AppColors.orange, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '450 000 FCFA',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _dashStat('${dataProvider.products.length}', 'Products'),
                      _dashStat('4.9 ★', 'Rating'),
                      _dashStat('1.2k', 'Followers'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.dark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.push(AppRoutes.addProduct),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    onPressed: () => context.push(AppRoutes.editCreatorProfile),
                    icon: Icon(Icons.edit_outlined, color: isDark ? Colors.white : AppColors.dark),
                    label: Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.dark)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Catalog',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${dataProvider.products.length} items',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dataProvider.products.length,
              itemBuilder: (context, index) {
                final product = dataProvider.products[index];
                final isLocalFile = !product.image.startsWith('http');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showProductOptions(context, product, index),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: isLocalFile
                                      ? FileImage(File(product.image)) as ImageProvider
                                      : NetworkImage(product.image),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${product.price} FCFA',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.orange),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.more_vert_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashStat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
