import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../generated/l10n/app_localizations.dart';

class CreatorProfileScreen extends StatelessWidget {
  const CreatorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(AppAssets.hero),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 52,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white).withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: 20, color: isDark ? Colors.white : AppColors.dark),
                    ),
                  ),
                ),
                // Avatar
                Positioned(
                  bottom: -40,
                  left: 20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                      image: const DecorationImage(
                        image: NetworkImage(AppAssets.model2),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 52),

            // Profile Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'MIDE Stores',
                                style: TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.dark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.verified_rounded, size: 20, color: Colors.blue),
                            ],
                          ),
                          Text(
                            'Dakar, Sénégal • Since 2019',
                            style: TextStyle(
                              fontSize: 12, 
                              color: isDark ? Colors.white38 : Colors.black45, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          backgroundColor: isDark ? AppColors.orange : AppColors.dark,
                          foregroundColor: isDark ? AppColors.dark : Colors.white,
                        ),
                        child: Text(l10n.follow, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Créatrice de boubous modernes, fusion entre wax authentique et coupes contemporaines. Atelier familial, production locale.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                  ),

                  const SizedBox(height: 24),
                  // Stats
                  Row(
                    children: [
                      _statItem(context, '124', l10n.products),
                      _statItem(context, '4.9', l10n.rating),
                      _statItem(context, '1.2k', 'Followers'),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // Portfolio Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          image: const DecorationImage(
                            image: NetworkImage(AppAssets.model1),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
