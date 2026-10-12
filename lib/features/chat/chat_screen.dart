import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/constants.dart';
import '../../core/api/repositories.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../shared/models/models.dart' as m;

/// One conversation, live.
///
/// The messages arrive over Supabase Realtime, and the socket carries the
/// session's JWT so RLS applies to it exactly as it does to a REST read. The
/// failure mode worth knowing: an unauthenticated socket is not an error, it
/// simply delivers nothing — a conversation that looks quiet rather than
/// broken. That is why the history is fetched over REST first; if the socket
/// is dead you still see what was already said.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.threadId});

  final String threadId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repo = ChatRepository();
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  List<m.Message> _messages = [];
  RealtimeChannel? _channel;
  bool _loading = true;
  Object? _error;
  bool _sending = false;

  String? get _me => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final msgs = await _repo.messages(widget.threadId);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _subscribe();
      unawaited(_repo.markRead(widget.threadId));
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _subscribe() {
    _channel = _repo.subscribeToThread(widget.threadId, (msg) {
      if (!mounted) return;
      // The sender already appended its own message optimistically, and the
      // insert comes back over the socket too — without this check every
      // message you send appears twice on your own screen.
      if (_messages.any((m) => m.id == msg.id)) return;
      setState(() => _messages = [..._messages, msg]);
      _scrollToEnd();
      unawaited(_repo.markRead(widget.threadId));
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    _controller.clear();
    try {
      final sent = await _repo.send(widget.threadId, body);
      if (!mounted) return;
      if (!_messages.any((m) => m.id == sent.id)) {
        setState(() => _messages = [..._messages, sent]);
      }
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      // Put the text back. Losing somebody's message because the network
      // blinked is the one thing a chat must not do.
      _controller.text = body;
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    final c = _channel;
    if (c != null) Supabase.instance.client.removeChannel(c);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
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
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(l10n.messagesTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: Column(
        children: [
          Expanded(child: _body(l10n, theme)),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(AppLocalizations l10n, ThemeData theme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: theme.hintColor),
            const SizedBox(height: 12),
            Text(l10n.somethingWrong),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: Text(l10n.retry)),
          ],
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(l10n.noMessages, style: TextStyle(color: theme.hintColor)),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        return _ChatBubble(
          message: msg.body,
          time: _time(msg.createdAt),
          isMe: msg.senderId == _me,
        );
      },
    );
  }

  static String _time(DateTime? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;

  const _ChatBubble({required this.message, required this.time, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.dark
                        : (isDark ? theme.cardColor : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      if (!isMe && !isDark)
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                    ],
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : (isDark ? Colors.white : AppColors.dark),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                      fontSize: 10, color: theme.hintColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
