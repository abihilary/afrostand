import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/widgets/animated_pressable.dart';
import '../../shared/widgets/typing_text.dart';

class SocialSwipeScreen extends StatefulWidget {
  const SocialSwipeScreen({super.key});

  @override
  State<SocialSwipeScreen> createState() => _SocialSwipeScreenState();
}

class _SocialSwipeScreenState extends State<SocialSwipeScreen> {
  final Map<int, bool> _likedPosts = {};

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _CommentModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: 5,
        itemBuilder: (context, index) {
          final isLiked = _likedPosts[index] ?? false;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Content Image
              Image.network(
                index % 2 == 0 ? AppAssets.model3 : AppAssets.model7,
                fit: BoxFit.cover,
              ),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Top Bar
              Positioned(
                top: 52,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.swipeAndSlay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        _topAction(Icons.remove_red_eye_outlined),
                        const SizedBox(width: 12),
                        _topAction(Icons.more_horiz_rounded),
                      ],
                    ),
                  ],
                ),
              ),

              // Interaction Buttons
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _interactionBtn(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded, 
                      isLiked ? '2.5k' : '2.4k', 
                      isActive: isLiked,
                      onTap: () => setState(() => _likedPosts[index] = !isLiked),
                    ),
                    const SizedBox(height: 20),
                    _interactionBtn(Icons.message_rounded, '128', onTap: () => _showComments(context)),
                    const SizedBox(height: 20),
                    _interactionBtn(Icons.share_rounded, l10n.share),
                  ],
                ),
              ),

              // Bottom Info
              Positioned(
                bottom: 40,
                left: 20,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedPressable(
                          onTap: () => context.push(AppRoutes.creatorProfile),
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(AppAssets.model2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aminata ${l10n.commentedOnLook}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedPressable(
                            onTap: () => setState(() => _likedPosts[index] = true),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              alignment: Alignment.center,
                              child: Text(l10n.adore, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedPressable(
                            onTap: () => _showComments(context),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              alignment: Alignment.center,
                              child: Text(l10n.comment, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _topAction(IconData icon) {
    return AnimatedPressable(
      onTap: () {},
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _interactionBtn(IconData icon, String label, {bool isActive = false, VoidCallback? onTap}) {
    return AnimatedPressable(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.orange : AppColors.dark,
              size: 20,
            ),
          ).animate(target: isActive ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms, curve: Curves.elasticOut),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CommentModal extends StatefulWidget {
  const _CommentModal();

  @override
  State<_CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<_CommentModal> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _comments = [
    {"user": "James Lee", "text": "Incroyable ce look ! 🔥", "avatar": AppAssets.model4},
    {"user": "Fatou N.", "text": "Où as-tu acheté le sac ?", "avatar": AppAssets.model8},
    {"user": "Creative Studio", "text": "Magnifique travail d'artisanat.", "avatar": AppAssets.model5},
  ];

  void _sendComment() {
    if (_commentController.text.trim().isEmpty) return;
    setState(() {
      _comments.add({
        "user": "Aminata",
        "text": _commentController.text.trim(),
        "avatar": AppAssets.model2,
      });
      _commentController.clear();
    });
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: 500,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(l10n.comment, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _comments.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16, 
                        backgroundImage: NetworkImage(_comments[index]["avatar"]!),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_comments[index]["user"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(_comments[index]["text"]!, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.1),
                ),
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    onSubmitted: (_) => _sendComment(),
                    decoration: InputDecoration(
                      hintText: '${l10n.writeMessage}...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                ),
                AnimatedPressable(
                  onTap: _sendComment,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(l10n.send, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
