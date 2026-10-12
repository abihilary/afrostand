import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/shop_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/animated_pressable.dart';

/// Saved items.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShopProvider>().loadWishlist();
    });
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
        title: Text(l10n.wishlist,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: shop.loadWishlist,
        child: shop.isLoading && shop.wishlist.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : shop.wishlist.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 140),
                      Icon(Icons.favorite_outline_rounded, size: 48, color: theme.hintColor),
                      const SizedBox(height: 16),
                      Center(
                          child: Text(shop.hasError ? l10n.somethingWrong : l10n.emptyWishlist,
                              style: const TextStyle(fontWeight: FontWeight.w700))),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.home),
                          child: Text(l10n.discover),
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.66,
                    ),
                    itemCount: shop.wishlist.length,
                    itemBuilder: (context, i) => _tile(shop.wishlist[i], shop, theme, l10n),
                  ),
      ),
    );
  }

  Widget _tile(Product p, ShopProvider shop, ThemeData theme, AppLocalizations l10n) {
    return AnimatedPressable(
      onTap: () => context.push(AppRoutes.productDetail(p.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.dividerColor,
                    image: p.imageUrl.isEmpty
                        ? null
                        : DecorationImage(image: NetworkImage(p.imageUrl), fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await shop.toggleWishlist(p.id);
                        await shop.loadWishlist();
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.black54,
                      child: const Icon(Icons.favorite_rounded,
                          size: 15, color: AppColors.orange),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          Text(p.creatorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: theme.hintColor)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('${p.effectivePriceLabel} FCFA',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await shop.addToCart(p);
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(
                        content: Text(l10n.addedToCart),
                        behavior: SnackBarBehavior.floating));
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
                child: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
