import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_snack.dart';

/// The seller's side.
///
/// Three states, because "can I sell" genuinely has three answers and the old
/// screen assumed the happy one: no shop yet, waiting on approval, or running
/// a shop. Approval is granted in SQL for now — there is no admin screen, and
/// pretending otherwise with a button that does nothing would be worse.
class CreatorDashboardScreen extends StatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().load();
      context.read<OrdersProvider>().loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.profile)),
        title: Text(profile.myCreator?.name ?? l10n.myShop,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          if (profile.canSell)
            IconButton(
              onPressed: () => context.push(AppRoutes.editCreatorProfile),
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
      floatingActionButton: profile.canSell
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.addProduct),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Article'),
            )
          : null,
      body: profile.isLoading && profile.me == null
          ? const Center(child: CircularProgressIndicator())
          : profile.canSell
              ? _shop(profile, l10n, theme)
              : _notYet(profile, l10n, theme),
    );
  }

  Widget _notYet(ProfileProvider profile, AppLocalizations l10n, ThemeData theme) {
    final status = profile.creatorStatus;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, size: 56, color: theme.hintColor),
            const SizedBox(height: 20),
            Text(
              switch (status) {
                CreatorStatus.requested => l10n.creatorRequested,
                CreatorStatus.rejected => l10n.creatorRejected,
                CreatorStatus.approved => l10n.myShop,
                CreatorStatus.none => l10n.becomeCreator,
              },
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              switch (status) {
                CreatorStatus.requested =>
                  'We will let you know once your shop is open.',
                CreatorStatus.approved =>
                  'Your shop is approved but has not been created yet.',
                _ => 'Sell your work to the whole marketplace.',
              },
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.hintColor, height: 1.5),
            ),
            const SizedBox(height: 28),
            if (status == CreatorStatus.none || status == CreatorStatus.rejected)
              ElevatedButton(
                onPressed: () async {
                  try {
                    await profile.requestCreatorStatus();
                  } catch (e) {
                    if (!mounted) return;
                    showError(context, e);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.dark,
                ),
                child: Text(l10n.becomeCreator),
              ),
          ],
        ),
      ),
    );
  }

  Widget _shop(ProfileProvider profile, AppLocalizations l10n, ThemeData theme) {
    final sales = context.watch<OrdersProvider>().sales;
    final creator = profile.myCreator!;
    // Only the lines that belong to this shop. An order can contain other
    // shops' goods, and counting those as revenue would be wrong.
    final myLines = [
      for (final o in sales)
        for (final i in o.items)
          if (i.creatorId == creator.id) i,
    ];
    final revenue = myLines.fold(0, (s, i) => s + i.lineTotalXaf);
    // Only orders that have been paid for are waiting on the seller; an unpaid
    // one is waiting on the buyer and counting it would be a false queue.
    final toShip = [
      for (final o in sales)
        if (o.status == OrderStatus.paid || o.status == OrderStatus.shipped)
          for (final i in o.linesFor(creator.id))
            if (i.fulfilment == Fulfilment.pending) i,
    ].length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      children: [
        Row(
          children: [
            _stat('${profile.myProducts.length}', l10n.noProducts.split(' ').last, theme),
            _stat('${creator.followerCount}', l10n.followers, theme),
            _stat('${myLines.length}', l10n.mySales, theme),
          ],
        ),
        const SizedBox(height: 16),
        // The revenue card is now the door to the orders behind it. It used to
        // be a figure and nothing else: a seller could see that something had
        // sold and had no screen anywhere that let them send it.
        GestureDetector(
          onTap: () => context.push(AppRoutes.sales),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mySales,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    if (toShip > 0)
                      Text('$toShip ${l10n.toShip.toLowerCase()}',
                          style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                  ],
                ),
                const Spacer(),
                Text('${formatXaf(revenue)} FCFA',
                    style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.myShop, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 10),
        if (profile.myProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
                child: Text(l10n.noProducts, style: TextStyle(color: theme.hintColor))),
          )
        else
          ...profile.myProducts.map((p) => _productRow(p, profile, l10n, theme)),
      ],
    );
  }

  Widget _stat(String value, String label, ThemeData theme) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: theme.hintColor)),
            ],
          ),
        ),
      );

  Widget _productRow(
      Product p, ProfileProvider profile, AppLocalizations l10n, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.dividerColor,
              image: p.imageUrl.isEmpty
                  ? null
                  : DecorationImage(image: NetworkImage(p.imageUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text('${p.effectivePriceLabel} FCFA',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.orange)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              final router = GoRouter.of(context);
              if (v == 'view') {
                router.push(AppRoutes.productDetail(p.id));
              } else if (v == 'delist') {
                try {
                  // Delisted, not deleted: an order_item points at this row and
                  // a past order has to stay readable.
                  await profile.delistProduct(p.id);
                } catch (e) {
                  if (!mounted) return;
                  showError(context, e);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Text('Voir')),
              PopupMenuItem(value: 'delist', child: Text(l10n.delist)),
            ],
          ),
        ],
      ),
    );
  }
}
