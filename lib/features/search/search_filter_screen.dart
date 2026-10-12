import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import 'package:provider/provider.dart';
import '../../core/providers/catalog_provider.dart';
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
  List<Product> _all = [];
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    try {
      final items = await context.read<CatalogProvider>().search('');
      if (!mounted) return;
      setState(() {
        _all = items;
        _loading = false;
      });
      _filterProducts();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Debounced: the search runs server-side, and a query per keystroke on a
  /// mobile connection is a request the user has already invalidated by the
  /// time it lands.
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() => _results = _applyFilters(_all));
      return;
    }
    try {
      final found = await context.read<CatalogProvider>().search(q);
      if (!mounted) return;
      setState(() => _results = _applyFilters(found));
    } catch (_) {
      // Fall back to filtering what is already loaded rather than blanking
      // the screen on a flaky connection.
      if (mounted) {
        setState(() => _results = _applyFilters(_all.where((p) =>
            p.name.toLowerCase().contains(q.toLowerCase()) ||
            p.creatorName.toLowerCase().contains(q.toLowerCase())).toList()));
      }
    }
  }

  List<Product> _applyFilters(List<Product> source) {
    if (_activeFilters.isEmpty) return source;
    return source
        .where((p) => _activeFilters.any((f) =>
            p.tags.any((t) => t.toLowerCase() == f.toLowerCase()) ||
            p.name.toLowerCase().contains(f.toLowerCase())))
        .toList();
  }

  void _filterProducts() => setState(() => _results = _applyFilters(_all));

  @override
  void dispose() {
    _debounce?.cancel();
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
              child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
              ? Center(child: Text(AppLocalizations.of(context)!.noResults, style: TextStyle(color: theme.hintColor)))
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
                      onTap: () => context.push(AppRoutes.productDetail(product.id)),
                      child: _searchResultCard(
                        context,
                        product.name,
                        product.effectivePriceLabel,
                        product.imageUrl,
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
