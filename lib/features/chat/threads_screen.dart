import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes.dart';
import 'package:provider/provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../app/constants.dart';

/// The inbox.
///
/// New screen: there was a chat screen but no way to reach a second
/// conversation, because the route took no thread and the app had exactly one
/// hardcoded exchange in it.
class ThreadsScreen extends StatefulWidget {
  const ThreadsScreen({super.key});

  @override
  State<ThreadsScreen> createState() => _ThreadsScreenState();
}

class _ThreadsScreenState extends State<ThreadsScreen> {
  // Through the provider rather than the repository, because the unread count
  // is shown on the profile too — and a badge that only updates while you are
  // looking at the inbox is worse than no badge.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChatProvider>().load();
    });
  }

  Future<void> _load() => context.read<ChatProvider>().load();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home)),
        title: Text(l10n.messagesTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _body(chat, l10n, theme),
      ),
    );
  }

  Widget _body(ChatProvider chat, AppLocalizations l10n, ThemeData theme) {
    final threads = chat.threads;
    if (chat.isLoading && threads.isEmpty) return const Center(child: CircularProgressIndicator());
    if (chat.hasError && threads.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off_rounded, size: 40, color: theme.hintColor),
          const SizedBox(height: 12),
          Center(child: Text(l10n.somethingWrong)),
          const SizedBox(height: 16),
          Center(child: OutlinedButton(onPressed: _load, child: Text(l10n.retry))),
        ],
      );
    }
    if (threads.isEmpty) {
      // Scrollable even when empty, so pull-to-refresh still works — an empty
      // list you cannot refresh is a dead end.
      return ListView(
        children: [
          const SizedBox(height: 140),
          Icon(Icons.forum_outlined, size: 48, color: theme.hintColor),
          const SizedBox(height: 16),
          Center(
              child: Text(l10n.noMessages,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      );
    }

    return ListView.separated(
      itemCount: threads.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, i) {
        final t = threads[i];
        // Was 'AfroStand', so a conversation with somebody who has not set a
        // name read as a message from the company itself.
        final name = t.other?.fullName?.trim().isNotEmpty == true
            ? t.other!.fullName!.trim()
            : l10n.someone;
        return ListTile(
          onTap: () async {
            await context.push(AppRoutes.chat(t.id));
            // The thread just got marked read, so every count on this screen
            // and the badge on the profile are now one conversation stale.
            if (context.mounted) {
              await context.read<ChatProvider>().refreshQuietly();
            }
          },
          leading: CircleAvatar(
            backgroundImage:
                t.other?.avatarUrl != null ? NetworkImage(t.other!.avatarUrl!) : null,
            child: t.other?.avatarUrl == null
                ? Text(name.characters.first.toUpperCase())
                : null,
          ),
          title: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          subtitle: t.lastBody == null
              ? null
              : Text(t.lastBody!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: t.unread > 0 ? FontWeight.w700 : FontWeight.w400,
                      color: t.unread > 0 ? null : theme.hintColor)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (t.lastMessageAt != null)
                Text(_when(t.lastMessageAt!, l10n),
                    style: TextStyle(fontSize: 11, color: theme.hintColor)),
              if (t.unread > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text('${t.unread}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.dark)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Was 'now', 'm', 'h' and then 'j' — English abbreviations with a French
  // one for days, in the same column of the same list.
  static String _when(DateTime t, AppLocalizations l10n) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return l10n.justNow;
    if (d.inHours < 1) return l10n.minutesShort(d.inMinutes);
    if (d.inDays < 1) return l10n.hoursShort(d.inHours);
    if (d.inDays < 7) return l10n.daysShort(d.inDays);
    return '${t.day}/${t.month}';
  }
}
