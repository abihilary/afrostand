import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../app/routes.dart';

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
      context.go(AppRoutes.welcome);
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
          _MarketplaceSlide(onStart: () => context.go(AppRoutes.welcome)),
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
    return Column(
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
          title: 'Découvrez un monde de shopping avec ',
          highlight: 'Afrostand',
          subtitle: 'Des créateurs locaux, des pièces uniques, faites main avec amour.',
          buttonText: 'Continuer',
          onPressed: onNext,
          pageIndex: 0,
        ),
      ],
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
    return Container(
      color: AppColors.sand,
      child: Column(
        children: [
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, color: Colors.white, size: 14),
                      SizedBox(width: 8),
                      Text(
                        'SOCIAL SHOPPING',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Shopping is better with friends',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Partage tes looks, demande l’avis de tes proches, shoppez ensemble en temps réel.',
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Floating cards visualization
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                Positioned(
                  left: 24,
                  top: 0,
                  child: _floatingImage(AppAssets.model6, 180),
                ),
                Positioned(
                  right: 24,
                  top: 60,
                  child: _floatingImage(AppAssets.model7, 200),
                ),
                Positioned(
                  left: 24,
                  bottom: 20,
                  child: _commentCard('Aminata', 'J’adore ce boubou! 😍'),
                ),
                Positioned(
                  right: 40,
                  top: 20,
                  child: _messageBubble('James Lee', 'Ce look te va trop bien!'),
                ),
              ],
            ),
          ),
          _bottomContent(
            title: '',
            highlight: '',
            subtitle: '',
            buttonText: 'Continuer',
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
      width: 160,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  Widget _commentCard(String name, String comment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 14, backgroundColor: AppColors.cream),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(comment, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(String name, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 11, color: Colors.white60)),
          const SizedBox(height: 2),
          Text(message, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
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
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 48,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'African Print\nMarketplace',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Authentique, traçable, durable. Chaque pièce raconte une histoire de savoir-faire.',
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _statItem('100%', 'Fait Main'),
                    const SizedBox(width: 8),
                    _statItem('250+', 'Créateurs'),
                    const SizedBox(width: 8),
                    _statItem('12k+', 'Pièces'),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.dark,
                  ),
                  child: const Text('Commencer l’aventure'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

Widget _bottomContent({
  required String title,
  required String highlight,
  required String subtitle,
  required String buttonText,
  required VoidCallback onPressed,
  required int pageIndex,
  bool showText = true,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
    child: Column(
      children: [
        if (showText) ...[
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black, height: 1.1),
              children: [
                TextSpan(text: title),
                TextSpan(text: highlight, style: const TextStyle(color: AppColors.orange)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
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
                color: active ? AppColors.dark : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    ),
  );
}
