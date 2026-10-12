import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/widgets/animated_pressable.dart';
import '../../shared/widgets/shimmer_placeholder.dart';
import '../../shared/models/models.dart';
import '../../core/providers/catalog_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/shop_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _selectedFilter;
  bool _isLoading = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedFilter = AppLocalizations.of(context)!.local;
  }

  Future<void> _changeFilter(String filter) async {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _isLoading = true;
    });
    // Artificial delay for shimmer effect
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filters = [l10n.local, l10n.sustainable, l10n.gift, l10n.handmade];

    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    // Was 'Aminata' for anybody without a name set. Greeting a stranger by
    // somebody else's name is a small thing that makes an app feel fake.
    final profileP = context.watch<ProfileProvider>();
    final catalog = context.watch<CatalogProvider>();
    final cartCount = context.watch<ShopProvider>().cartCount;
    final fullName = profileP.me?.fullName ??
        user?.userMetadata?['full_name'] ??
        user?.email?.split('@').first ??
        l10n.appName;

    // The four filters are category slugs. Banner copy comes from the
    // categories table, the items from the catalogue - these six-product
    // lists used to be literals that duplicated the seed and drifted from it
    // the moment anybody listed something new.
    const slugs = ['local', 'sustainable', 'gift', 'handmade'];
    final slug = slugs[filters.indexOf(_selectedFilter).clamp(0, slugs.length - 1)];
    final category =
        catalog.categories.where((c) => c.slug == slug).firstOrNull;
    final items = catalog.taggedLocally(category?.name ?? slug);

    final activeCollection = CollectionData(
      bannerTitle: category?.name ?? _selectedFilter,
      bannerSubtitle: category?.description ?? l10n.collectionDesc,
      bannerImage: category?.imageUrl ?? '',
      products: items,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.cardColor,
                        border: Border.all(color: theme.dividerColor),
                        image: (profileP.me?.avatarUrl?.isNotEmpty ?? false)
                            ? DecorationImage(
                                image: NetworkImage(profileP.me!.avatarUrl!),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: (profileP.me?.avatarUrl?.isNotEmpty ?? false)
                          ? null
                          : Icon(Icons.person_outline_rounded,
                              size: 20, color: theme.hintColor),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.goodMorning,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white38 : Colors.black.withOpacity(0.4),
                          ),
                        ),
                        Text(
                          '$fullName 👋',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _headerAction(Icons.favorite_outline_rounded,
                        onTap: () => context.push(AppRoutes.wishlist)),
                    const SizedBox(width: 8),
                    // Was the literal 2, so an empty cart wore a badge saying
                    // there were two things in it.
                    _headerAction(Icons.shopping_bag_outlined,
                        badgeCount: cartCount == 0 ? null : cartCount,
                        onTap: () => context.go(AppRoutes.cart)),
                  ],
                ).animate().fade(duration: 400.ms).slideY(begin: -0.2),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.searchFilter),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, color: isDark ? Colors.white24 : Colors.black.withOpacity(0.3), size: 20),
                              const SizedBox(width: 12),
                              Text(
                                l10n.searchPlaceholder,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white38 : Colors.black45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.searchFilter),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.dark,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.orange, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Filter Chips
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filters.length,
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected = filter == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AnimatedPressable(
                        onTap: () => _changeFilter(filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.dark : theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : theme.dividerColor,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.dark),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Banner
              _isLoading
                  ? const BannerShimmer()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.dark,
                          borderRadius: BorderRadius.circular(24),
                          image: DecorationImage(
                            image: NetworkImage(activeCollection.bannerImage.isEmpty
                                ? (items.isNotEmpty ? items.first.imageUrl : '')
                                : activeCollection.bannerImage),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.35),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.exclusive,
                                style: const TextStyle(
                                  color: AppColors.dark,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activeCollection.bannerTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activeCollection.bannerSubtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.dark,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                context.push(AppRoutes.categoryFeed(slug));
                              },
                              child: Text(
                                l10n.discover,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(duration: 400.ms),
                    ),

              const SizedBox(height: 32),

              // Categories Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.categories,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.search),
                      child: Text(
                        l10n.seeAll,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.orange : AppColors.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Five hardcoded names over stock photographs, and a tap that
              // built its URL out of a function reference. These are the real
              // categories now, and tapping one opens that category.
              SizedBox(
                height: 90,
                child: catalog.categories.isEmpty
                    ? const SizedBox.shrink()
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          for (final c in catalog.categories) _categoryItem(context, c),
                        ],
                      ),
              ),

              const SizedBox(height: 32),

              // Featured Products
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.featuredProducts,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.searchFilter),
                      child: Text(
                        '${l10n.filter} ›',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.orange : AppColors.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _isLoading
                  ? const ShimmerPlaceholder()
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: activeCollection.products.length,
                      itemBuilder: (context, index) {
                        final product = activeCollection.products[index];
                        return _productCard(context, product);
                      },
                    ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerAction(IconData icon, {int? badgeCount, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: isDark ? Colors.white : AppColors.dark),
            if (badgeCount != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryItem(BuildContext context, ProductCategory c) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final image = c.imageUrl ?? '';

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: AnimatedPressable(
        onTap: () => context.go(AppRoutes.categoryFeed(c.slug)),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardColor,
                image: image.isEmpty
                    ? null
                    : DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
                border: Border.all(
                  color: isDark ? Colors.white24 : AppColors.orange.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              c.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressable(
      onTap: () {
        context.push(AppRoutes.productDetail(product.id));
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                      image: DecorationImage(
                        image: NetworkImage(product.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.cardColor.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        size: 16,
                        color: isDark ? Colors.white : AppColors.dark,
                      ),
                    ),
                  ),
                  if (product.isNew || product.isDiscounted)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.isNew ? AppColors.dark : AppColors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.isNew ? 'NEW' : product.discountLabel!,
                          style: TextStyle(
                            color: product.isNew ? Colors.white : AppColors.dark,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.creatorName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.effectivePriceLabel} FCFA',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.orange : AppColors.dark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1);
  }
}

class CollectionData {
  final String bannerTitle;
  final String bannerSubtitle;
  final String bannerImage;
  final List<Product> products;

  CollectionData({
    required this.bannerTitle,
    required this.bannerSubtitle,
    required this.bannerImage,
    required this.products,
  });
}
