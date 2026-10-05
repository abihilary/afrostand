import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/product.dart';
import '../../shared/widgets/animated_pressable.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<String> _activeFilters = [
    "Wax",
    "Fait Main",
    "Dakar",
  ];

  List<Product> _results = [];

  @override
  void initState() {
    super.initState();
    _results = allMockProducts;
  }

  void _onSearchChanged(String query) {
    _filterProducts();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _results = allMockProducts.where((product) {
        final matchesQuery = product.name.toLowerCase().contains(query) || 
                            product.creator.toLowerCase().contains(query) ||
                            product.tags.any((tag) => tag.toLowerCase().contains(query));
        
        final matchesFilters = _activeFilters.isEmpty || 
                              _activeFilters.any((f) => 
                                product.tags.any((t) => t.toLowerCase() == f.toLowerCase()) ||
                                product.name.toLowerCase().contains(f.toLowerCase())
                              );

        return matchesQuery && matchesFilters;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Search Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            child: Row(
              children: [
                AnimatedPressable(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_rounded, size: 20, color: isDark ? Colors.white : AppColors.dark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 18, color: isDark ? Colors.white38 : Colors.black.withOpacity(0.4)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: l10n.searchPlaceholder,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              fillColor: Colors.transparent,
                            ),
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.dark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.filters,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white38 : Colors.black45,
                        letterSpacing: 1,
                      ),
                    ),
                    AnimatedPressable(
                      onTap: () => setState(() {
                        _activeFilters.clear();
                        _filterProducts();
                      }),
                      child: const Text(
                        'RESET',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _activeFilters.map((filter) {
                    return AnimatedPressable(
                      onTap: () => setState(() {
                        _activeFilters.remove(filter);
                        _filterProducts();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.orange : AppColors.dark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              filter,
                              style: TextStyle(
                                color: isDark ? AppColors.dark : Colors.white, 
                                fontSize: 11, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.close_rounded, color: isDark ? AppColors.dark : Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ).animate().scale(duration: 200.ms);
                  }).toList(),
                ),
              ],
            ),
          ),

          // Results Grid
          Expanded(
            child: AnimatedSwitcher(
              duration: 300.ms,
              child: _results.isEmpty 
              ? Center(child: Text("No results found", style: TextStyle(color: theme.hintColor)))
              : GridView.builder(
                  key: ValueKey(_results.length),
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final product = _results[index];
                    return AnimatedPressable(
                      onTap: () => context.push('${AppRoutes.home}/${AppRoutes.productDetail}'),
                      child: _searchResultCard(
                        context,
                        product.name,
                        product.price,
                        product.image,
                      ),
                    ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.1);
                  },
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchResultCard(BuildContext context, String name, String price, String url) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              url,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$price FCFA',
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.orange : AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
