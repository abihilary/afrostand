import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/catalog_provider.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/providers/social_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/animated_pressable.dart';

/// One product.
///
/// Took no argument before this and rendered a hardcoded image, name and price
/// regardless of what was tapped — the screen was a mockup of a product page
/// rather than a page for a product.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedColor = 0;
  String _selectedSize = 'M';
  int _imageIndex = 0;

  Product? _product;
  List<Product> _more = [];
  bool _loading = true;
  Object? _error;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final catalog = context.read<CatalogProvider>();
    try {
      final p = await catalog.product(widget.productId);
      if (!mounted) return;
      List<Product> more = [];
      if (p != null) {
        more = (await catalog.productsByCreator(p.creatorId))
            .where((x) => x.id != p.id)
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _product = p;
        _more = more;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  List<String> get _images {
    final p = _product;
    if (p == null) return const [];
    return [p.imageUrl, ...p.gallery].where((u) => u.isNotEmpty).toList();
  }

  Future<void> _addToCart({bool thenCheckout = false}) async {
    final p = _product;
    if (p == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    setState(() => _adding = true);
    try {
      await context.read<ShopProvider>().addToCart(
            p,
            size: _selectedSize,
            color: _colorNames.elementAt(_selectedColor),
          );
      if (!mounted) return;
      if (thenCheckout) {
        router.push(AppRoutes.cart);
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.addedToCart),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      // Most often "sign in to use the cart". Said plainly rather than
      // swallowed, because a button that does nothing is the complaint this
      // whole pass started from.
      messenger.showSnackBar(SnackBar(
        content: Text('$e'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  static const _colorNames = ['Orange', 'Bleu', 'Teal'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final product = _product;
    if (product == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: theme.hintColor),
                const SizedBox(height: 16),
                Text(
                  _error == null
                      ? 'This item is no longer available.'
                      : 'Could not load this item.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: _load, child: Text(l10n.retry)),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final shop = context.watch<ShopProvider>();
    final social = context.watch<SocialProvider>();
    final isFavorited = shop.isWishlisted(product.id);
    final isFollowing = social.isFollowing(product.creatorId);
    final images = _images;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 480,
                        width: double.infinity,
                        child: images.isEmpty
                            ? Container(color: theme.dividerColor)
                            : PageView.builder(
                                itemCount: images.length,
                                onPageChanged: (i) => setState(() => _imageIndex = i),
                                itemBuilder: (context, i) => Image.network(
                                  images[i],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: theme.dividerColor,
                                    child: Icon(Icons.image_not_supported_outlined,
                                        color: theme.hintColor),
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 52,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _topAction(Icons.arrow_back_rounded, onTap: () => context.pop()),
                            Row(
                              children: [
                                _topAction(
                                  isFavorited
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_outline_rounded,
                                  color: isFavorited ? AppColors.orange : null,
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      await shop.toggleWishlist(product.id);
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(SnackBar(content: Text('$e')));
                                    }
                                  },
                                ),
                                const SizedBox(width: 12),
                                _topAction(Icons.share_outlined),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < images.length; i++)
                                _pageIndicator(i == _imageIndex),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                  // The "LIMITED - ONLY 5 LEFT" badge that used
                                  // to sit here is gone. There is no stock
                                  // column and never was, so it was invented
                                  // urgency on every product in the catalogue.
                                  // When stock exists it can come back meaning
                                  // something.
                                  if (product.isNew) ...[
                                    const SizedBox(height: 6),
                                    _chip(l10n.newLabel, AppColors.orange),
                                  ],
                                ],
                              ),
                            ).animate().fade(delay: 200.ms).slideX(begin: -0.1),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${product.effectivePriceLabel} FCFA',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? AppColors.orange : AppColors.dark,
                                  ),
                                ),
                                if (product.isDiscounted)
                                  Text(
                                    '${product.priceLabel} FCFA',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.hintColor,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _creatorCard(product, isFollowing, social, theme, isDark),
                        const SizedBox(height: 32),
                        if (product.description != null) ...[
                          Text(
                            l10n.description.toUpperCase(),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: theme.hintColor,
                                letterSpacing: 1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            product.description!,
                            style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.6),
                          ),
                          const SizedBox(height: 32),
                        ],
                        Text(
                          'COLOR',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.hintColor,
                              letterSpacing: 1),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _colorOption(0, Colors.orange),
                            _colorOption(1, Colors.blue),
                            _colorOption(2, Colors.teal),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.size.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.hintColor,
                              letterSpacing: 1),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: ['S', 'M', 'L', 'XL'].map((s) {
                            final isSelected = _selectedSize == s;
                            return AnimatedPressable(
                              onTap: () => setState(() => _selectedSize = s),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? AppColors.orange : AppColors.dark)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: isSelected ? Colors.transparent : theme.dividerColor),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    color: isSelected
                                        ? (isDark ? AppColors.dark : Colors.white)
                                        : (isDark ? Colors.white60 : AppColors.dark),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40),
                        if (_more.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('More from this Creator',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              Icon(Icons.arrow_forward_rounded, size: 18, color: theme.hintColor),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _more.length,
                              itemBuilder: (context, index) {
                                final other = _more[index];
                                return AnimatedPressable(
                                  onTap: () =>
                                      context.push(AppRoutes.productDetail(other.id)),
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      image: DecorationImage(
                                        image: NetworkImage(other.imageUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _adding ? null : () => _addToCart(),
                    child: _adding
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.addToCart),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    // Adds, then goes to the cart. "Buy now" used to navigate
                    // to the home screen, which bought nothing and lost the
                    // product you were looking at.
                    onPressed: _adding ? null : () => _addToCart(thenCheckout: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.orange : AppColors.dark,
                      foregroundColor: isDark ? AppColors.dark : Colors.white,
                    ),
                    child: Text(l10n.buyNow),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      );

  Widget _creatorCard(
      Product product, bool isFollowing, SocialProvider social, ThemeData theme, bool isDark) {
    final creator = product.creator;
    final name = creator?.name ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.creatorProfile(product.creatorId)),
            child: CircleAvatar(
              radius: 20,
              backgroundImage:
                  creator?.avatarUrl != null ? NetworkImage(creator!.avatarUrl!) : null,
              child: creator?.avatarUrl == null
                  ? Text(name.isEmpty ? '?' : name.characters.first.toUpperCase())
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                // The hardcoded "4.9 (124 reviews)" is gone with the scarcity
                // badge, for the same reason: there is no reviews table, so it
                // was a number the product could not stand behind.
                if (creator?.location != null)
                  Text(creator!.location!,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: theme.hintColor)),
              ],
            ),
          ),
          AnimatedPressable(
            onTap: () => context.push(AppRoutes.creatorProfile(product.creatorId)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('View',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedPressable(
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await social.toggleFollow(product.creatorId);
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFollowing ? Colors.transparent : AppColors.orange,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: isFollowing ? theme.dividerColor : Colors.transparent),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isFollowing ? theme.textTheme.bodyMedium?.color : AppColors.dark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topAction(IconData icon, {Color? color, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? (isDark ? Colors.white : AppColors.dark), size: 20),
      ),
    ).animate(target: color != null ? 1 : 0).scale(
        begin: const Offset(1, 1),
        end: const Offset(1.2, 1.2),
        duration: 200.ms,
        curve: Curves.elasticOut);
  }

  Widget _pageIndicator(bool active) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: active ? 16 : 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: active
            ? (isDark ? AppColors.orange : Colors.white)
            : (isDark ? Colors.white24 : Colors.white.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _colorOption(int index, Color color) {
    final isSelected = _selectedColor == index;
    return AnimatedPressable(
      onTap: () => setState(() => _selectedColor = index),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.orange : Colors.transparent,
            width: 2,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
        ),
        child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
      ),
    );
  }
}
