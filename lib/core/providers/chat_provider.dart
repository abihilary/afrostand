import 'package:flutter/foundation.dart';
import '../api/repositories.dart';
import '../../shared/models/models.dart';
import 'catalog_provider.dart' show Loadable;

/// The inbox.
///
/// A provider rather than a repository call inside the screen, because the
/// unread count has to be readable from somewhere that is not the inbox — the
/// whole point of a badge is that you see it before you open the thing it
/// counts.
class ChatProvider extends ChangeNotifier with Loadable {
  final _repo = ChatRepository();

  List<ChatThread> _threads = [];
  List<ChatThread> get threads => _threads;

  /// Across every conversation. Zero when signed out, because [clearLocal]
  /// runs on sign-out and a badge left over from the last person to use the
  /// phone would be somebody else's mail.
  int get unreadTotal => _threads.fold(0, (s, t) => s + t.unread);

  Future<void> load() => guard(() async {
        _threads = await _repo.threads();
      });

  /// After opening a thread: the messages in it have just been marked read, so
  /// the badge is wrong until this runs. Quiet — no spinner, since nothing on
  /// screen is waiting for it.
  Future<void> refreshQuietly() async {
    try {
      _threads = await _repo.threads();
      notifyListeners();
    } catch (_) {
      // A stale count is not worth an error state over.
    }
  }

  void clearLocal() {
    _threads = [];
    notifyListeners();
  }
}
