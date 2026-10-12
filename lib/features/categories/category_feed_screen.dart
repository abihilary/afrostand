import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/catalog_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/animated_pressable.dart';

/// A collection.
///
/// Took the title and a banner image as query parameters, which meant the
/// screen knew what to call itself but not what was in it. It takes a slug and
/// asks the database — `byCategorySlug` matches on the tag as well as the
/// foreign key, because the catalogue tags consistently and assigns categories
/// rarely, and a shelf that honoured only the FK would be near-empty.
class CategoryFeedScreen extends StatefulWidget {
  const CategoryFeedScreen({super.key, required this.slug});

  final String slug;

  @override
  State<CategoryFeedScreen> createState() => _CategoryFeedScreenState();
}

class _CategoryFeedScreenState extends State<CategoryFeedScreen> {
  List<Product> _products = [];
  ProductCategory? _category;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final catalog = context.read<CatalogProvider>();
    try {
      final items = await catalog.byCategorySlug(widget.slug);
      if (!mounted) return;
      setState(() {
        _products = items;
        _category = catalog.categories
            .where((c) => c.slug == widget.slug)
            .firstOrNull;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cat = _category;
    final title = cat?.name ?? widget.slug;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            // The title sits on top of a photograph, so it cannot inherit the
            // theme's dark-on-light text: over the banner it was black on a
            // dark image and effectively unreadable. Dark bar, white text,
            // which also holds once the bar collapses.
            backgroundColor: AppColors.dark,
            foregroundColor: Colors.white,
            leading: BackButton(
              color: Colors.white,
              onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (cat?.imageUrl != null)
                    Image.network(cat!.imageUrl!, fit: BoxFit.cover)
                  else
                    Container(color: AppColors.dark),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (cat?.description != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(cat!.description!,
                    style: TextStyle(fontSize: 13, color: theme.hintColor, height: 1.5)),
              ),
            ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 40, color: theme.hintColor),
                    const SizedBox(height: 12),
                    Text(l10n.somethingWrong),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _load, child: Text(l10n.retry)),
                  ],
                ),
              ),
            )
          else if (_products.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Center(
                    child: Text(l10n.noProducts, style: TextStyle(color: theme.hintColor))),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.70,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _tile(_products[i], theme),
                  childCount: _products.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _tile(Product p, ThemeData theme) => AnimatedPressable(
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
                          : DecorationImage(
                              image: NetworkImage(p.imageUrl), fit: BoxFit.cover),
                    ),
                  ),
                  if (p.isDiscounted)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(p.discountLabel!,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.dark)),
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
            Text('${p.effectivePriceLabel} FCFA',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}
