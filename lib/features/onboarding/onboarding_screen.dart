import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../shared/widgets/typing_text.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  void _next() {
    if (_currentPage == 2) {
      context.go(AppRoutes.home);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          _DiscoverySlide(onNext: _next),
          _SocialSlide(onNext: _next),
          _MarketplaceSlide(onStart: () => context.go(AppRoutes.home)),
        ],
      ),
    );
  }
}

class _DiscoverySlide extends StatelessWidget {
  final VoidCallback onNext;
  const _DiscoverySlide({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _collageItem(AppAssets.model1, 2, 2),
                  _collageItem(AppAssets.model2, 1, 1),
                  _collageItem(AppAssets.model3, 1, 1),
                  _collageItem(AppAssets.model4, 1, 1),
                  _collageItem(AppAssets.model5, 2, 1),
                ],
              ),
            ),
          ),
          _bottomContent(
            context: context,
            title: AppLocalizations.of(context)!.discoveryTitle,
            highlight: 'Afrostand',
            subtitle: AppLocalizations.of(context)!.discoverySubtitle,
            buttonText: AppLocalizations.of(context)!.continueBtn,
            onPressed: onNext,
            pageIndex: 0,
          ),
        ],
      ),
    );
  }

  Widget _collageItem(String url, int cross, int main) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }
}

class _SocialSlide extends StatelessWidget {
  final VoidCallback onNext;
  const _SocialSlide({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF16100D) : AppColors.sand,
      child: Column(
        children: [
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.orange : AppColors.dark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, color: isDark ? AppColors.dark : Colors.white, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.socialShopping,
                        style: TextStyle(color: isDark ? AppColors.dark : Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TypingText(
                  text: AppLocalizations.of(context)!.socialTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -1,
                    color: isDark ? Colors.white : AppColors.dark,
                  ),
                ).animate().fade(duration: 600.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.socialSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : Colors.black54, height: 1.5),
                ).animate().fade(delay: 200.ms, duration: 600.ms),
              ],
            ),
          ),
          
          Expanded(
            child: Center(
              child: SizedBox(
                height: 400,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 10,
                      top: 40,
                      child: _floatingImage(AppAssets.model6, 220)
                          .animate().fade(duration: 800.ms).slideX(begin: -0.2),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 40,
                      child: _floatingImage(AppAssets.model7, 240)
                          .animate().fade(duration: 800.ms).slideX(begin: 0.2),
                    ),
                    
                    Positioned(
                      top: 120,
                      right: 30,
                      child: _messageBubble(
                        context, 
                        'James Lee', 
                        AppLocalizations.of(context)!.messageJames
                      ).animate().fade(delay: 1.seconds).scale(begin: const Offset(0.8, 0.8)),
                    ),
                    Positioned(
                      bottom: 80,
                      left: 30,
                      child: _commentCard(
                        context, 
                        'Aminata', 
                        AppLocalizations.of(context)!.commentAminata
                      ).animate().fade(delay: 1.5.seconds).scale(begin: const Offset(0.8, 0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          _bottomContent(
            context: context,
            title: '',
            highlight: '',
            subtitle: '',
            buttonText: AppLocalizations.of(context)!.continueBtn,
            onPressed: onNext,
            pageIndex: 1,
            showText: false,
          ),
        ],
      ),
    );
  }

  Widget _floatingImage(String url, double height) {
    return Container(
      width: 180,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  Widget _commentCard(BuildContext context, String name, String comment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 16, backgroundImage: NetworkImage(AppAssets.model2)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              TypingText(
                text: comment,
                duration: const Duration(milliseconds: 40),
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(BuildContext context, String name, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: isDark ? AppColors.orange : AppColors.dark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontSize: 11, color: isDark ? AppColors.dark.withOpacity(0.6) : Colors.white60, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TypingText(
            text: message,
            duration: const Duration(milliseconds: 30),
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.dark : Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceSlide extends StatelessWidget {
  final VoidCallback onStart;
  const _MarketplaceSlide({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          flex: 52,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(AppAssets.hero, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ANKARA • KENTE • BOGOLAN',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.dark),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 48,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TypingText(
                  text: AppLocalizations.of(context)!.marketplaceTitle,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1, color: isDark ? Colors.white : AppColors.dark),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.marketplaceSubtitle,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _statItem(context, '100%', AppLocalizations.of(context)!.handmade),
                    const SizedBox(width: 8),
                    _statItem(context, '250+', AppLocalizations.of(context)!.creators),
                    const SizedBox(width: 8),
                    _statItem(context, '12k+', AppLocalizations.of(context)!.pieces),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.dark,
                  ),
                  child: Text(AppLocalizations.of(context)!.startAdventure),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : AppColors.sand,
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

Widget _bottomContent({
  required BuildContext context,
  required String title,
  required String highlight,
  required String subtitle,
  required String buttonText,
  required VoidCallback onPressed,
  required int pageIndex,
  bool showText = true,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
    child: Column(
      children: [
        if (showText) ...[
          TypingText(
            text: "$title$highlight",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black, height: 1.1),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 24),
        ],
        ElevatedButton(
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(buttonText),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final active = index == pageIndex;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: active ? 24 : 6,
              height: 4,
              decoration: BoxDecoration(
                color: active ? (isDark ? AppColors.orange : AppColors.dark) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    ),
  );
}
