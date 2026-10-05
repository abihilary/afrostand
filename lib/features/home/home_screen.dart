import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
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
                        const Text(
                          'Aminata 👋',
                          style: TextStyle(
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
                                l10n.search,
                                style: TextStyle(
                                  color: isDark ? Colors.white24 : Colors.black.withOpacity(0.3),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedPressable(
                      onTap: () {},
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.orange : AppColors.dark,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(Icons.tune_rounded, color: isDark ? AppColors.dark : Colors.white, size: 20),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 100.ms).slideY(begin: 0.2),
              ),

              // Filters
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: filters.map((f) {
                    final isSelected = _selectedFilter == f;
                    final activeColor = isDark ? AppColors.orange : AppColors.dark;
                    final inactiveColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.05);
                    
                    return AnimatedPressable(
                      onTap: () => _changeFilter(f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? activeColor : theme.dividerColor,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isSelected 
                                ? (isDark ? AppColors.dark : Colors.white) 
                                : (isDark ? Colors.white60 : Colors.black.withOpacity(0.6)),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ).animate().fade(delay: 200.ms).slideX(begin: 0.2),
              ),

              // Dynamic Banner
              const SizedBox(height: 24),
              _isLoading 
                ? const BannerShimmer()
                : AnimatedSwitcher(
                    duration: 400.ms,
                    transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
                    child: Padding(
                      key: ValueKey(_selectedFilter),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A1A) : AppColors.dark,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20, top: 0, bottom: 0,
                              child: Opacity(
                                opacity: 0.6,
                                child: Image.network(
                                  activeCollection.bannerImage,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.orange,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      l10n.exclusive,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                  ).animate(onPlay: (c) => c.repeat())
                                   .shimmer(duration: 2.seconds),
                                  const SizedBox(height: 12),
                                  Text(
                                    activeCollection.bannerTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    activeCollection.bannerSubtitle,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Discover', // Should use l10n.discover if available
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

              // Categories
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.categories,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      l10n.seeAll,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _categoryItem(context, 'Wax', AppAssets.model1),
                    _categoryItem(context, 'Bijoux', AppAssets.model2),
                    _categoryItem(context, 'Cuir', AppAssets.model6),
                    _categoryItem(context, 'Raphia', AppAssets.model5),
                    _categoryItem(context, l10n.sustainable, AppAssets.model8),
                    _categoryItem(context, l10n.gift, AppAssets.model7),
                  ],
                ).animate().fade(delay: 300.ms).slideX(begin: 0.2),
              ),

              // Featured Products
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.featuredProducts,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Row(
                      children: [
                        Text(
                          l10n.filter,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 16, color: theme.textTheme.bodySmall?.color),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _isLoading 
                ? const ShimmerPlaceholder()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedSwitcher(
                      duration: 400.ms,
                      child: GridView.count(
                        key: ValueKey(_selectedFilter),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: activeCollection.products.map((p) {
                          return _productCard(
                            context,
                            p.name,
                            p.creator,
                            p.price,
                            p.image,
                            isNew: p.isNew,
                            discount: p.discount,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerAction(IconData icon, {int badgeCount = 0, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressable(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor),
            ),
            child: Icon(icon, color: isDark ? Colors.white : AppColors.dark, size: 20),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryItem(BuildContext context, String label, String url) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: AnimatedPressable(
        onTap: () => _changeFilter(label),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(BuildContext context, String name, String creator, String price, String url, {bool isNew = false, String? discount}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressable(
      onTap: () => context.push('${AppRoutes.home}/${AppRoutes.productDetail}'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(url, fit: BoxFit.cover),
                  if (isNew || discount != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.orange : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: Text(
                          discount ?? 'NEW',
                          style: TextStyle(
                            fontSize: 9, 
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.dark : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.cardColor.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Icon(Icons.favorite_outline_rounded, size: 14, color: isDark ? Colors.white : AppColors.dark),
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
                    name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    creator,
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black.withOpacity(0.4), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        'FCFA',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
