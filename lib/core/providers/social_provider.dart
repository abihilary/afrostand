import 'package:flutter/foundation.dart';
import '../api/repositories.dart';
import '../../shared/models/models.dart';
import 'catalog_provider.dart' show Loadable;

/// The feed, likes, comments and follows.
class SocialProvider extends ChangeNotifier with Loadable {
  final _repo = SocialRepository();

  List<Post> _feed = [];
  List<Creator> _followed = [];
  Set<String> _followedIds = {};

  List<Post> get feed => _feed;
  List<Creator> get followedCreators => _followed;
  bool isFollowing(String creatorId) => _followedIds.contains(creatorId);

  Future<void> loadFeed() => guard(() async {
        _feed = await _repo.feed();
        _followedIds = await _repo.followedCreatorIds();
      });

  Future<void> loadFollowed() => guard(() async {
        _followed = await _repo.followedCreators();
        _followedIds = _followed.map((c) => c.id).toSet();
      });

  void clearLocal() {
    _followed = [];
    _followedIds = {};
    _feed = [for (final p in _feed) p.copyWith(likedByMe: false)];
    notifyListeners();
  }

  /// Optimistic, and reverted if the write is refused.
  ///
  /// A like that waits for the network before filling in reads as a dropped
  /// tap, and the reflex is to tap again — which is how a like becomes an
  /// unlike. The revert is what keeps the optimism honest.
  Future<void> toggleLike(String postId) async {
    final i = _feed.indexWhere((p) => p.id == postId);
    if (i == -1) return;
    final before = _feed[i];
    final on = !before.likedByMe;

    _feed[i] = before.copyWith(
      likedByMe: on,
      likeCount: (before.likeCount + (on ? 1 : -1)).clamp(0, 1 << 30),
    );
    notifyListeners();

    try {
      await _repo.like(postId, on);
    } catch (e) {
      _feed[i] = before;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleFollow(String creatorId) async {
    final on = !_followedIds.contains(creatorId);
    on ? _followedIds.add(creatorId) : _followedIds.remove(creatorId);
    notifyListeners();
    try {
      await _repo.follow(creatorId, on);
    } catch (e) {
      on ? _followedIds.remove(creatorId) : _followedIds.add(creatorId);
      notifyListeners();
      rethrow;
    }
  }

  Future<List<PostComment>> comments(String postId) => _repo.comments(postId);

  Future<PostComment> comment(String postId, String body) async {
    final c = await _repo.comment(postId, body);
    final i = _feed.indexWhere((p) => p.id == postId);
    if (i != -1) {
      _feed[i] = _feed[i].copyWith(commentCount: _feed[i].commentCount + 1);
      notifyListeners();
    }
    return c;
  }
}
