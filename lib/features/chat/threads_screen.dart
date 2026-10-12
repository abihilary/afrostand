import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes.dart';
import '../../core/api/repositories.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart';

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
  final _repo = ChatRepository();
  List<ChatThread> _threads = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final t = await _repo.threads();
      if (!mounted) return;
      setState(() {
        _threads = t;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
        child: _body(l10n, theme),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, ThemeData theme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
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
    if (_threads.isEmpty) {
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
      itemCount: _threads.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, i) {
        final t = _threads[i];
        final name = t.other?.fullName ?? 'AfroStand';
        return ListTile(
          onTap: () => context.push(AppRoutes.chat(t.id)),
          leading: CircleAvatar(
            backgroundImage:
                t.other?.avatarUrl != null ? NetworkImage(t.other!.avatarUrl!) : null,
            child: t.other?.avatarUrl == null
                ? Text(name.characters.first.toUpperCase())
                : null,
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          subtitle: t.lastBody == null
              ? null
              : Text(t.lastBody!, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: t.lastMessageAt == null
              ? null
              : Text(_when(t.lastMessageAt!),
                  style: TextStyle(fontSize: 11, color: theme.hintColor)),
        );
      },
    );
  }

  static String _when(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inDays < 1) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}j';
    return '${t.day}/${t.month}';
  }
}
