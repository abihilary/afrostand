import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/providers/social_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/widgets/app_snack.dart';

/// The shops you follow.
class FollowedCreatorsScreen extends StatefulWidget {
  const FollowedCreatorsScreen({super.key});

  @override
  State<FollowedCreatorsScreen> createState() => _FollowedCreatorsScreenState();
}

class _FollowedCreatorsScreenState extends State<FollowedCreatorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SocialProvider>().loadFollowed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final social = context.watch<SocialProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.profile)),
        title: Text(l10n.followedCreators,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: social.loadFollowed,
        child: social.isLoading && social.followedCreators.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : social.followedCreators.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 140),
                      Icon(Icons.storefront_outlined, size: 48, color: theme.hintColor),
                      const SizedBox(height: 16),
                      Center(
                          child: Text(l10n.noFollowed,
                              style: const TextStyle(fontWeight: FontWeight.w700))),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.creators),
                          child: Text(l10n.discover),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: social.followedCreators.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: theme.dividerColor),
                    itemBuilder: (context, i) {
                      final c = social.followedCreators[i];
                      return ListTile(
                        onTap: () => context.push(AppRoutes.creatorProfile(c.id)),
                        leading: CircleAvatar(
                          backgroundImage:
                              c.avatarUrl != null ? NetworkImage(c.avatarUrl!) : null,
                          child: c.avatarUrl == null
                              ? Text(c.name.characters.first.toUpperCase())
                              : null,
                        ),
                        title: Text(c.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        subtitle: Text(
                          [
                            if (c.location != null) c.location!,
                            '${c.followerCount} ${l10n.followers}',
                          ].join(' • '),
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            try {
                              await social.toggleFollow(c.id);
                              await social.loadFollowed();
                            } catch (e) {
                              if (!context.mounted) return;
                              showError(context, e);
                            }
                          },
                          child: Text(l10n.unfollow),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
