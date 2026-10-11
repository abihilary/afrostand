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
import '../../shared/models/product.dart';

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
    final fullName = user?.userMetadata?['full_name'] ?? user?.email?.split('@').first ?? 'Aminata';

    // Data for each collection
    final collections = {
      l10n.local: CollectionData(
        bannerTitle: l10n.newCollection,
        bannerSubtitle: l10n.collectionDesc,
        bannerImage: AppAssets.model4,
        products: [
          Product(name: 'Boubou Wax Royal', creator: 'MIDE Stores', price: '8 000', image: AppAssets.model1, isNew: true),
          Product(name: 'Ensemble Ankara', creator: 'Aïsha K.', price: '12 500', image: AppAssets.model3, discount: '-30%'),
          Product(name: 'Tunique Kente', creator: 'Ghanart', price: '10 500', image: AppAssets.model4),
          Product(name: 'Robe Indigo', creator: 'Indigo Studio', price: '14 200', image: AppAssets.model7, isNew: true),
          Product(name: 'Veste Bogolan', creator: 'MIDE Stores', price: '18 000', image: AppAssets.hero),
          Product(name: 'Jupe Plissée Wax', creator: 'Aïsha K.', price: '7 500', image: AppAssets.model2),
        ],
      ),
      l10n.sustainable: CollectionData(
        bannerTitle: 'Eco-Fashion 2025',
        bannerSubtitle: 'Mode éthique et durable par nos artisans.',
        bannerImage: AppAssets.model8,
        products: [
          Product(name: 'Sac Raphia Tressé', creator: 'Atelier Dakar', price: '9 800', image: AppAssets.model5),
          Product(name: 'Sandales Cuir Bio', creator: 'Maro Dakar', price: '7 400', image: AppAssets.model6, isNew: true),
          Product(name: 'Panier Osier', creator: 'Nature Art', price: '5 200', image: AppAssets.model8),
          Product(name: 'Ceinture Jute', creator: 'Eco Wear', price: '3 500', image: AppAssets.model1),
          Product(name: 'Tote Bag Coton', creator: 'Atelier Dakar', price: '4 000', image: AppAssets.model3),
          Product(name: 'Pochette Sisal', creator: 'Nature Art', price: '6 800', image: AppAssets.model5, isNew: true),
        ],
      ),
      l10n.gift: CollectionData(
        bannerTitle: 'Cadeaux Uniques',
        bannerSubtitle: 'Offrez le meilleur de l’artisanat africain.',
        bannerImage: AppAssets.model7,
        products: [
          Product(name: 'Boucles Cauri Gold', creator: 'Bijoux Baobab', price: '3 200', image: AppAssets.model2, isNew: true),
          Product(name: 'Chemise Bogolan', creator: 'MIDE Stores', price: '6 500', image: AppAssets.model4),
          Product(name: 'Masque Sculpté', creator: 'Heritage', price: '25 000', image: AppAssets.hero, discount: '-15%'),
          Product(name: 'Écharpe Soie Sauvage', creator: 'Artisanat Mali', price: '12 000', image: AppAssets.model3),
          Product(name: 'Bougie Parfumée', creator: 'Dakar Scent', price: '4 500', image: AppAssets.model6),
          Product(name: 'Coffret Épices', creator: 'Terroir', price: '8 900', image: AppAssets.model5, isNew: true),
        ],
      ),
      l10n.handmade: CollectionData(
        bannerTitle: 'Savoir-faire Manuel',
        bannerSubtitle: 'Chaque pièce est une œuvre d’art unique.',
        bannerImage: AppAssets.model5,
        products: [
          Product(name: 'Tissage Traditionnel', creator: 'Kente Craft', price: '15 000', image: AppAssets.hero, isNew: true),
          Product(name: 'Potterie Artisanale', creator: 'Dakar Art', price: '4 500', image: AppAssets.model2),
          Product(name: 'Tableau Batik', creator: 'Galerie Nomade', price: '32 000', image: AppAssets.model7),
          Product(name: 'Poupée Akan', creator: 'Heritage', price: '6 000', image: AppAssets.model4),
          Product(name: 'Vase Céramique', creator: 'Dakar Art', price: '9 500', image: AppAssets.model8),
          Product(name: 'Statue Bronze', creator: 'Heritage', price: '45 000', image: AppAssets.model1, isNew: true),
        ],
      ),
    };

    final activeCollection = collections[_selectedFilter] ?? collections[l10n.local]!;

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
                        image: const DecorationImage(
                          image: NetworkImage(AppAssets.model2),
                          fit: BoxFit.cover,
                        ),
                      ),
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
                    _headerAction(Icons.favorite_outline_rounded, onTap: () {}),
                    const SizedBox(width: 8),
                    _headerAction(Icons.shopping_bag_outlined, badgeCount: 2, onTap: () {
                      context.push(AppRoutes.cart);
                    }),
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
                            image: NetworkImage(activeCollection.bannerImage),
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
                                context.go('${AppRoutes.home}/${AppRoutes.categoryFeed}?title=${Uri.encodeComponent(activeCollection.bannerTitle)}&image=${Uri.encodeComponent(activeCollection.bannerImage)}');
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
                      onPressed: () {},
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

              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _categoryItem(context, l10n.local, AppAssets.model1),
                    _categoryItem(context, 'Bijoux', AppAssets.model2),
                    _categoryItem(context, 'Cuir', AppAssets.model3),
                    _categoryItem(context, 'Raphia', AppAssets.model4),
                    _categoryItem(context, l10n.sustainable, AppAssets.model5),
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

  Widget _categoryItem(BuildContext context, String title, String imageUrl) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: AnimatedPressable(
        onTap: () {
          context.go('${AppRoutes.home}/${AppRoutes.categoryFeed}?title=${Uri.encodeComponent(title)}&image=${Uri.encodeComponent(imageUrl)}');
        },
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
                border: Border.all(
                  color: isDark ? Colors.white24 : AppColors.orange.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
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
        context.push('${AppRoutes.home}/${AppRoutes.productDetail}', extra: product);
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
                        image: NetworkImage(product.image),
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
                  if (product.isNew || product.discount != null)
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
                          product.isNew ? 'NEW' : product.discount!,
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
                    product.creator,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.price} FCFA',
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
