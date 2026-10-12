import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/providers/social_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/animated_pressable.dart';
import '../../shared/widgets/app_snack.dart';

/// The feed — full-screen posts, one per swipe.
///
/// Five hardcoded cards with two alternating stock images before this, and a
/// comment sheet whose comments were a literal in the file. Now `posts`,
/// `post_likes` and `post_comments`, all public to read and own-writes-only.
class SocialSwipeScreen extends StatefulWidget {
  const SocialSwipeScreen({super.key});

  @override
  State<SocialSwipeScreen> createState() => _SocialSwipeScreenState();
}

class _SocialSwipeScreenState extends State<SocialSwipeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SocialProvider>().loadFeed();
    });
  }

  void _showComments(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CommentSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final social = context.watch<SocialProvider>();

    if (social.isLoading && social.feed.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (social.feed.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                social.hasError ? Icons.cloud_off_rounded : Icons.photo_library_outlined,
                size: 48,
                color: Colors.white38,
              ),
              const SizedBox(height: 16),
              Text(social.hasError ? l10n.somethingWrong : l10n.nothingHere,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: social.loadFeed,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: social.loadFeed,
        child: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: social.feed.length,
          itemBuilder: (context, index) {
            final post = social.feed[index];
            return _PostCard(
              post: post,
              onLike: () async {
                try {
                  await social.toggleLike(post.id);
                } catch (e) {
                  if (!context.mounted) return;
                  showError(context, e);
                }
              },
              onComment: () => _showComments(context, post),
            );
          },
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onLike, required this.onComment});

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          post.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: Colors.grey.shade900),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black38, Colors.transparent, Colors.black87],
              stops: [0, 0.4, 1],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              _action(
                post.likedByMe ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                '${post.likeCount}',
                onLike,
                color: post.likedByMe ? AppColors.orange : Colors.white,
              ),
              const SizedBox(height: 20),
              _action(Icons.mode_comment_outlined, '${post.commentCount}', onComment),
              const SizedBox(height: 20),
              _action(Icons.share_outlined, '', () {}),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 90,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedPressable(
                onTap: () => context.push(AppRoutes.creatorProfile(post.creatorId)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: post.creator?.avatarUrl != null
                          ? NetworkImage(post.creator!.avatarUrl!)
                          : null,
                      child: post.creator?.avatarUrl == null
                          ? Text(
                              (post.creator?.name ?? '?').characters.first.toUpperCase(),
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        post.creator?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              if (post.caption != null) ...[
                const SizedBox(height: 10),
                Text(post.caption!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
              ],
              if (post.productId != null) ...[
                const SizedBox(height: 12),
                AnimatedPressable(
                  onTap: () => context.push(AppRoutes.productDetail(post.productId!)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Voir l\'article',
                        style: TextStyle(
                            color: AppColors.dark,
                            fontWeight: FontWeight.w900,
                            fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return AnimatedPressable(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({required this.post});
  final Post post;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _controller = TextEditingController();
  List<PostComment> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await context.read<SocialProvider>().comments(widget.post.id);
      if (!mounted) return;
      setState(() {
        _comments = c;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      final c = await context.read<SocialProvider>().comment(widget.post.id, body);
      if (!mounted) return;
      setState(() => _comments = [..._comments, c]);
    } catch (e) {
      if (!mounted) return;
      _controller.text = body;
      showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
            Text(l10n.commentsTitle,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? Center(
                          child: Text(l10n.noComments,
                              style: TextStyle(color: theme.hintColor)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _comments.length,
                          itemBuilder: (context, i) {
                            final c = _comments[i];
                            final name = c.author?.fullName ?? 'AfroStand';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: c.author?.avatarUrl != null
                                        ? NetworkImage(c.author!.avatarUrl!)
                                        : null,
                                    child: c.author?.avatarUrl == null
                                        ? Text(name.characters.first.toUpperCase(),
                                            style: const TextStyle(fontSize: 12))
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800, fontSize: 12)),
                                        Text(c.body,
                                            style: const TextStyle(fontSize: 13, height: 1.4)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: l10n.addComment,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: theme.dividerColor)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
