import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/widgets/animated_pressable.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedColor = 0;
  String _selectedSize = "M";
  bool _isFavorited = false;
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 480,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(AppAssets.model1),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ).animate().shimmer(duration: 1.seconds),
                      Positioned(
                        top: 52,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _topAction(Icons.arrow_back_rounded, onTap: () => context.pop()),
                            Row(
                              children: [
                                _topAction(
                                  _isFavorited ? Icons.favorite_rounded : Icons.favorite_outline_rounded, 
                                  color: _isFavorited ? AppColors.orange : null,
                                  onTap: () => setState(() => _isFavorited = !_isFavorited),
                                ),
                                const SizedBox(width: 12),
                                _topAction(Icons.share_outlined),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _pageIndicator(true),
                            _pageIndicator(false),
                            _pageIndicator(false),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Boubou Wax Royal',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'LIMITED • ONLY 5 LEFT',
                                      style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                    ),
                                  ).animate(onPlay: (c) => c.repeat()).shimmer(delay: 2.seconds),
                                ],
                              ),
                            ).animate().fade(delay: 200.ms).slideX(begin: -0.1),
                            const SizedBox(width: 16),
                            Text(
                              '8 000 FCFA',
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.orange : AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.push(AppRoutes.creatorProfile),
                                child: const CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(AppAssets.model2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'MIDE STORES',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified_rounded, size: 14, color: Colors.blue),
                                      ],
                                    ),
                                    Text(
                                      '4.9 (124 reviews)',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.hintColor),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedPressable(
                                onTap: () => context.push(AppRoutes.creatorProfile),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedPressable(
                                onTap: () => setState(() => _isFollowing = !_isFollowing),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isFollowing ? Colors.transparent : AppColors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _isFollowing ? theme.dividerColor : Colors.transparent),
                                  ),
                                  child: Text(
                                    _isFollowing ? 'Following' : 'Follow', 
                                    style: TextStyle(
                                      fontSize: 11, 
                                      fontWeight: FontWeight.w800,
                                      color: _isFollowing ? theme.textTheme.bodyMedium?.color : AppColors.dark,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.description.toUpperCase(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.hintColor, letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Un boubou majestueux en tissu wax authentique. Fait main à Dakar avec une attention particulière aux détails.',
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.6),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'COLOR',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.hintColor, letterSpacing: 1),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _colorOption(0, Colors.orange),
                            _colorOption(1, Colors.blue),
                            _colorOption(2, Colors.teal),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.size.toUpperCase(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.hintColor, letterSpacing: 1),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: ['S', 'M', 'L', 'XL'].map((s) {
                            final isSelected = _selectedSize == s;
                            return AnimatedPressable(
                              onTap: () => setState(() => _selectedSize = s),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected ? (isDark ? AppColors.orange : AppColors.dark) : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? Colors.transparent : theme.dividerColor),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    color: isSelected ? (isDark ? AppColors.dark : Colors.white) : (isDark ? Colors.white60 : AppColors.dark),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40),
                        
                        // Other Items Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'More from this Creator',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            Icon(Icons.arrow_forward_rounded, size: 18, color: theme.hintColor),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              return AnimatedPressable(
                                onTap: () {},
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: NetworkImage(index % 2 == 0 ? AppAssets.model3 : AppAssets.model4),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedPressable(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.addedToCart),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: isDark ? AppColors.orange : AppColors.dark,
                        ),
                      );
                    },
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        disabledForegroundColor: isDark ? Colors.white : AppColors.dark,
                        disabledMouseCursor: SystemMouseCursors.click,
                      ),
                      child: Text(l10n.addToCart),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnimatedPressable(
                    onTap: () => context.go(AppRoutes.home),
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.orange : AppColors.dark,
                        disabledBackgroundColor: isDark ? AppColors.orange : AppColors.dark,
                        disabledForegroundColor: isDark ? AppColors.dark : Colors.white,
                      ),
                      child: Text(l10n.buyNow),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topAction(IconData icon, {Color? color, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? (isDark ? Colors.white : AppColors.dark), size: 20),
      ),
    ).animate(target: color != null ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms, curve: Curves.elasticOut);
  }

  Widget _pageIndicator(bool active) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: active ? 16 : 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: active ? (isDark ? AppColors.orange : Colors.white) : (isDark ? Colors.white24 : Colors.white.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _colorOption(int index, Color color) {
    final isSelected = _selectedColor == index;
    return AnimatedPressable(
      onTap: () => setState(() => _selectedColor = index),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.orange : Colors.transparent,
            width: 2,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
      ),
    );
  }
}
