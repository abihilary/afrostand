import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/providers/social_provider.dart';
import '../../shared/models/models.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/widgets/animated_pressable.dart';
import 'widgets/settings_modal.dart';
import '../../core/providers/chat_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SettingsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final profile = context.watch<ProfileProvider>();
    final shop = context.watch<ShopProvider>();
    final orders = context.watch<OrdersProvider>();
    final social = context.watch<SocialProvider>();

    final chat = context.watch<ChatProvider>();

    // Was 'Aminata Diallo', and under it the literal 'aminata@email.com •
    // Dakar'. The home screen had this fixed; this screen did not, so your own
    // profile page greeted you as somebody else and printed a stranger's
    // address. The profile row is the first source now — it is the one the
    // account can actually change — then the sign-up metadata, then the email,
    // and only then an honest placeholder.
    final fullName = profile.me?.fullName?.trim().isNotEmpty == true
        ? profile.me!.fullName!.trim()
        : (user?.userMetadata?['full_name'] as String?)?.trim().isNotEmpty == true
            ? (user!.userMetadata!['full_name'] as String).trim()
            : user?.email?.split('@').first ?? l10n.guestLabel;
    final email = user?.email ?? l10n.noEmail;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            color: theme.cardColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: theme.dividerColor,
                        image: profile.me?.avatarUrl == null
                            ? null
                            : DecorationImage(
                                image: NetworkImage(profile.me!.avatarUrl!),
                                fit: BoxFit.cover),
                      ),
                      alignment: Alignment.center,
                      child: profile.me?.avatarUrl != null
                          ? null
                          : Text(
                              profile.displayName.characters.first.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.dark,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12, 
                              color: isDark ? Colors.white38 : Colors.black45, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.orange : AppColors.sand,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  !auth.isAuthenticated
                                      ? l10n.guestLabel
                                      : switch (profile.creatorStatus) {
                                          CreatorStatus.approved =>
                                            l10n.myShop.toUpperCase(),
                                          CreatorStatus.requested =>
                                            l10n.creatorRequested.toUpperCase(),
                                          _ => l10n.verified.toUpperCase(),
                                        },
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.dark : null,
                                  ),
                                ),
                              ).animate(onPlay: (controller) => controller.repeat())
                               .shimmer(delay: 2.seconds, duration: 1.5.seconds, color: Colors.white60),
                              const Spacer(),
                              if (!auth.isAuthenticated)
                                TextButton(
                                  onPressed: () => context.push(AppRoutes.welcome),
                                  child: Text(l10n.signIn,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _profileStat(context, '${orders.orders.length}', l10n.orders),
                    _profileStat(context, '${shop.wishlistCount}', l10n.favorites),
                    _profileStat(
                        context, '${social.followedCount}', l10n.followedCreators),
                  ],
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _menuItem(context, Icons.storefront_rounded, l10n.myShop,
                    profile.canSell ? '${profile.myProducts.length}' : l10n.becomeCreator, 0, onTap: () => context.push(AppRoutes.creatorDashboard)),
                _menuItem(context, Icons.shopping_bag_outlined, l10n.myOrders, '${orders.orders.length}', 1, onTap: () => context.push(AppRoutes.orders)),
                _menuItem(context, Icons.favorite_outline_rounded, l10n.wishlist, '${shop.wishlistCount} ${l10n.items}', 2, onTap: () => context.push(AppRoutes.wishlist)),
                _menuItem(context, Icons.location_on_outlined, l10n.addresses, '${shop.addresses.length}', 3, onTap: () => context.push(AppRoutes.addresses)),
                _menuItem(context, Icons.credit_card_rounded, l10n.payments, '${shop.paymentMethods.length}', 4, onTap: () => context.push(AppRoutes.paymentMethods)),
                // /messages was routed from the day the inbox was written and
                // nothing in the app ever navigated to it. You could be taken
                // into a conversation from a shop page and, once you left it,
                // had no way back to it at all.
                _menuItem(context, Icons.chat_bubble_outline_rounded, l10n.messages,
                    chat.unreadTotal == 0 ? '' : '${chat.unreadTotal}', 5,
                    onTap: () => context.push(AppRoutes.threads)),
                _menuItem(context, Icons.grid_view_rounded, l10n.followedCreators, '${social.followedCount}', 6, onTap: () => context.push(AppRoutes.followedCreators)),
                _menuItem(context, Icons.settings_outlined, l10n.settings, '', 7, onTap: () => _showSettings(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileStat(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, String trailing, int index, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: isDark ? AppColors.orange : AppColors.dark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  if (trailing.isNotEmpty)
                    Text(trailing, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white24 : Colors.black.withOpacity(0.2)),
          ],
        ),
      ),
    ).animate().fade(delay: (400 + index * 50).ms).slideX(begin: 0.1);
  }
}
