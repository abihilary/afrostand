import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/widgets/animated_pressable.dart';

class FollowedCreatorsScreen extends StatelessWidget {
  const FollowedCreatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final List<Map<String, String>> creators = [
      {'name': 'MIDE Stores', 'avatar': AppAssets.model2, 'location': 'Dakar, Sénégal'},
      {'name': 'Aïsha K.', 'avatar': AppAssets.model4, 'location': 'Bamako, Mali'},
      {'name': 'Atelier Dakar', 'avatar': AppAssets.model6, 'location': 'Dakar, Sénégal'},
      {'name': 'Ghanart', 'avatar': AppAssets.model1, 'location': 'Accra, Ghana'},
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.followedCreators,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: creators.length,
        itemBuilder: (context, index) {
          final creator = creators[index];
          return AnimatedPressable(
            onTap: () => context.push(AppRoutes.creatorProfile),
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
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(creator['avatar']!),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(creator['name']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, size: 14, color: Colors.blue),
                          ],
                        ),
                        Text(creator['location']!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: BorderSide(color: isDark ? AppColors.orange : AppColors.dark),
                    ),
                    child: Text(
                      'Unfollow',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.orange : AppColors.dark),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
