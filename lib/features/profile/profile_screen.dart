import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/widgets/animated_pressable.dart';
import 'widgets/settings_modal.dart';

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
                        image: const DecorationImage(image: NetworkImage(AppAssets.model2), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aminata Diallo',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.dark,
                            ),
                          ),
                          Text(
                            'aminata@email.com • Dakar',
                            style: TextStyle(
                              fontSize: 12, 
                              color: isDark ? Colors.white38 : Colors.black45, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.orange : AppColors.sand,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${l10n.memberGold} • 320 ${l10n.points}',
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.dark : null,
                              ),
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                           .shimmer(delay: 2.seconds, duration: 1.5.seconds, color: Colors.white60),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _profileStat(context, '12', l10n.orders),
                    _profileStat(context, '34', l10n.favorites),
                    _profileStat(context, '5', l10n.followedCreators),
                  ],
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _menuItem(context, Icons.shopping_bag_outlined, l10n.myOrders, '3 ${l10n.inProgress}', 0, onTap: () => context.push(AppRoutes.orders)),
                _menuItem(context, Icons.favorite_outline_rounded, l10n.wishlist, '34 ${l10n.items}', 1, onTap: () => context.push(AppRoutes.wishlist)),
                _menuItem(context, Icons.location_on_outlined, l10n.addresses, '2 ${l10n.addresses.toLowerCase()}', 2, onTap: () => context.push(AppRoutes.addresses)),
                _menuItem(context, Icons.credit_card_rounded, l10n.payments, 'Wave • Visa', 3, onTap: () => context.push(AppRoutes.paymentMethods)),
                _menuItem(context, Icons.grid_view_rounded, l10n.followedCreators, '5', 4, onTap: () => context.push(AppRoutes.followedCreators)),
                _menuItem(context, Icons.settings_outlined, l10n.settings, '', 5, onTap: () => _showSettings(context)),
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
