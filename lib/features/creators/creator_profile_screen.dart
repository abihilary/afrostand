import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/api/repositories.dart';
import '../../core/providers/catalog_provider.dart';
import '../../core/providers/social_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/animated_pressable.dart';
import '../../shared/widgets/app_snack.dart';

/// A shop.
///
/// Took no creator id before, so every "view shop" link opened the same
/// hardcoded page. Follow now writes to `follows`, and Message opens a real
/// thread through `open_thread()` — which is why a shop with no account behind
/// it (the seeded ones) cannot be messaged, and says so instead of opening an
/// empty conversation.
class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({super.key, required this.creatorId});

  final String creatorId;

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  Creator? _creator;
  List<Product> _products = [];
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
      final c = await catalog.creator(widget.creatorId);
      final p = await catalog.productsByCreator(widget.creatorId);
      if (!mounted) return;
      setState(() {
        _creator = c;
        _products = p;
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

  Future<void> _message() async {
    final creator = _creator;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final owner = creator?.profileId;

    if (owner == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('This shop has no account behind it yet.'),
      ));
      return;
    }
    try {
      final threadId = await ChatRepository().openThread(owner);
      if (!mounted) return;
      router.push(AppRoutes.chat(threadId));
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
    }
  }

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

    final creator = _creator;
    if (creator == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_outlined, size: 48, color: theme.hintColor),
              const SizedBox(height: 12),
              Text(_error == null ? l10n.nothingHere : l10n.somethingWrong),
              if (_error != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(onPressed: _load, child: Text(l10n.retry)),
              ],
            ],
          ),
        ),
      );
    }

    final social = context.watch<SocialProvider>();
    final following = social.isFollowing(creator.id);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: BackButton(
              onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: creator.bannerUrl != null
                  ? Image.network(creator.bannerUrl!, fit: BoxFit.cover)
                  : Container(color: AppColors.dark),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: creator.avatarUrl != null
                            ? NetworkImage(creator.avatarUrl!)
                            : null,
                        child: creator.avatarUrl == null
                            ? Text(creator.name.characters.first.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w900))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(creator.name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w900)),
                            if (creator.location != null)
                              Text(creator.location!,
                                  style:
                                      TextStyle(fontSize: 12, color: theme.hintColor)),
                            const SizedBox(height: 4),
                            Text(
                              '${creator.followerCount} ${l10n.followers} • ${_products.length} ${l10n.items}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (creator.bio != null) ...[
                    const SizedBox(height: 16),
                    Text(creator.bio!,
                        style: TextStyle(fontSize: 13, height: 1.5, color: theme.hintColor)),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedPressable(
                          onTap: () async {
                            try {
                              await social.toggleFollow(creator.id);
                            } catch (e) {
                              if (!context.mounted) return;
                              showError(context, e);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: following
                                  ? Colors.transparent
                                  : (isDark ? AppColors.orange : AppColors.dark),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: following ? theme.dividerColor : Colors.transparent),
                            ),
                            child: Text(
                              following ? l10n.unfollow : l10n.follow,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: following
                                    ? theme.textTheme.bodyMedium?.color
                                    : (isDark ? AppColors.dark : Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedPressable(
                          onTap: _message,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Text(l10n.messagesTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          if (_products.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(l10n.noProducts, style: TextStyle(color: theme.hintColor)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
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

  Widget _tile(Product p, ThemeData theme) {
    return AnimatedPressable(
      onTap: () => context.push(AppRoutes.productDetail(p.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.dividerColor,
                image: p.imageUrl.isEmpty
                    ? null
                    : DecorationImage(image: NetworkImage(p.imageUrl), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          Text('${p.effectivePriceLabel} FCFA',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900, color: theme.hintColor)),
        ],
      ),
    );
  }
}
