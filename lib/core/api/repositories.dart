/// Every read and write the app makes, in one place.
///
/// Thin on purpose: each method is a query and a parse. No caching, no merging,
/// no business rules — those belong in the providers above or in Postgres
/// below. Anything that decides *what a thing is worth* lives in SQL, because
/// the anon key is public and this layer runs on the customer's phone.
///
/// Note what is NOT here: no method computes an order total, and none inserts
/// into `orders`. That is `place_order()`'s job. A repository that could write
/// a total would be a repository someone could patch the APK to lie with.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/models.dart';

SupabaseClient get _db => Supabase.instance.client;
String? get _uid => _db.auth.currentUser?.id;

/// Joined shape used anywhere a product is shown with its shop.
const _productCols = '*, creators(*)';

List<Map<String, dynamic>> _rows(dynamic res) =>
    (res as List).map((e) => (e as Map).cast<String, dynamic>()).toList();

// ───────────────────────────────────────────────────────────────────────────
// Catalogue
// ───────────────────────────────────────────────────────────────────────────
class CatalogRepository {
  Future<List<ProductCategory>> categories() async {
    final res = await _db.from('categories').select().order('sort');
    return _rows(res).map(ProductCategory.fromJson).toList();
  }

  Future<List<Product>> products({int limit = 50}) async {
    final res = await _db
        .from('products')
        .select(_productCols)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(limit);
    return _rows(res).map(Product.fromJson).toList();
  }

  Future<Product?> product(String id) async {
    final res = await _db.from('products').select(_productCols).eq('id', id).maybeSingle();
    return res == null ? null : Product.fromJson(res);
  }

  /// A collection, by category slug.
  ///
  /// Matches on the tag as well as the foreign key. The seeded catalogue tags
  /// products far more consistently than it assigns a category — two thirds
  /// have no category_id — so a feed that only honoured the FK would show a
  /// near-empty shelf for most slugs. The tag is the taxonomy people actually
  /// maintain; category_id is the tidier one nobody fills in.
  Future<List<Product>> byCategorySlug(String slug, {int limit = 60}) async {
    final cat = await _db.from('categories').select('id,name').eq('slug', slug).maybeSingle();
    final tag = (cat?['name'] ?? slug).toString();

    final byTag = await _db
        .from('products')
        .select(_productCols)
        .eq('is_active', true)
        .contains('tags', [tag]).limit(limit);

    final out = {for (final r in _rows(byTag)) r['id'].toString(): Product.fromJson(r)};

    if (cat != null) {
      final byCat = await _db
          .from('products')
          .select(_productCols)
          .eq('is_active', true)
          .eq('category_id', cat['id'])
          .limit(limit);
      for (final r in _rows(byCat)) {
        out.putIfAbsent(r['id'].toString(), () => Product.fromJson(r));
      }
    }
    return out.values.toList();
  }

  /// Free-text over name and description, plus an exact tag match.
  Future<List<Product>> search(String term, {int limit = 40}) async {
    final t = term.trim();
    if (t.isEmpty) return products(limit: limit);
    final res = await _db
        .from('products')
        .select(_productCols)
        .eq('is_active', true)
        .or('name.ilike.%$t%,description.ilike.%$t%')
        .limit(limit);
    final out = {for (final r in _rows(res)) r['id'].toString(): Product.fromJson(r)};

    final tagged = await _db
        .from('products')
        .select(_productCols)
        .eq('is_active', true)
        .contains('tags', [t]).limit(limit);
    for (final r in _rows(tagged)) {
      out.putIfAbsent(r['id'].toString(), () => Product.fromJson(r));
    }
    return out.values.toList();
  }

  Future<List<Creator>> creators({int limit = 50}) async {
    final res = await _db
        .from('creators')
        .select('*, follows(count), products(count)')
        .order('name')
        .limit(limit);
    return _rows(res).map(Creator.fromJson).toList();
  }

  Future<Creator?> creator(String id) async {
    final res = await _db
        .from('creators')
        .select('*, follows(count), products(count)')
        .eq('id', id)
        .maybeSingle();
    return res == null ? null : Creator.fromJson(res);
  }

  Future<List<Product>> productsByCreator(String creatorId) async {
    final res = await _db
        .from('products')
        .select(_productCols)
        .eq('creator_id', creatorId)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return _rows(res).map(Product.fromJson).toList();
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Cart, wishlist, addresses, payment methods
// ───────────────────────────────────────────────────────────────────────────
class ShopRepository {
  Future<List<CartItem>> cart() async {
    if (_uid == null) return [];
    final res = await _db
        .from('cart_items')
        .select('*, products($_productCols)')
        .order('added_at', ascending: false);
    return _rows(res).map(CartItem.fromJson).toList();
  }

  /// Upsert on the natural key, so tapping "add" twice makes a quantity of two
  /// rather than two identical lines. size and color default to '' rather than
  /// null for the same reason — see the note on the unique index in the schema.
  Future<void> addToCart(String productId, {int qty = 1, String size = '', String color = ''}) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Sign in to use the cart');
    final existing = await _db
        .from('cart_items')
        .select('id,qty')
        .eq('product_id', productId)
        .eq('size', size)
        .eq('color', color)
        .maybeSingle();
    if (existing == null) {
      await _db.from('cart_items').insert({
        'user_id': uid,
        'product_id': productId,
        'qty': qty,
        'size': size,
        'color': color,
      });
    } else {
      await _db
          .from('cart_items')
          .update({'qty': (existing['qty'] as int) + qty}).eq('id', existing['id']);
    }
  }

  Future<void> setQty(String cartItemId, int qty) async {
    if (qty <= 0) return removeFromCart(cartItemId);
    await _db.from('cart_items').update({'qty': qty}).eq('id', cartItemId);
  }

  Future<void> removeFromCart(String cartItemId) async =>
      _db.from('cart_items').delete().eq('id', cartItemId);

  Future<void> clearCart() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('cart_items').delete().eq('user_id', uid);
  }

  Future<List<Product>> wishlist() async {
    if (_uid == null) return [];
    final res = await _db.from('wishlist').select('products($_productCols)');
    return _rows(res)
        .map((r) => r['products'])
        .whereType<Map>()
        .map((p) => Product.fromJson(p.cast<String, dynamic>()))
        .toList();
  }

  Future<void> toggleWishlist(String productId, bool on) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Sign in to save items');
    if (on) {
      await _db.from('wishlist').upsert({'user_id': uid, 'product_id': productId});
    } else {
      await _db.from('wishlist').delete().eq('user_id', uid).eq('product_id', productId);
    }
  }

  Future<Set<String>> wishlistIds() async {
    if (_uid == null) return {};
    final res = await _db.from('wishlist').select('product_id');
    return _rows(res).map((r) => r['product_id'].toString()).toSet();
  }

  Future<List<Address>> addresses() async {
    if (_uid == null) return [];
    final res = await _db
        .from('addresses')
        .select()
        .order('is_default', ascending: false)
        .order('created_at');
    return _rows(res).map(Address.fromJson).toList();
  }

  Future<Address> saveAddress({
    String? id,
    String? label,
    required String fullName,
    required String phone,
    required String line1,
    String? line2,
    required String city,
    String country = 'CM',
    bool isDefault = false,
  }) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Sign in first');
    final payload = {
      'user_id': uid,
      'label': label,
      'full_name': fullName,
      'phone': phone,
      'line1': line1,
      'line2': line2,
      'city': city,
      'country': country,
      'is_default': isDefault,
    };
    // Only one default. Cleared before the write so a failure leaves the
    // previous default standing rather than leaving the account with none.
    if (isDefault) {
      await _db.from('addresses').update({'is_default': false}).eq('user_id', uid);
    }
    final res = id == null
        ? await _db.from('addresses').insert(payload).select().single()
        : await _db.from('addresses').update(payload).eq('id', id).select().single();
    return Address.fromJson(res);
  }

  Future<void> deleteAddress(String id) async => _db.from('addresses').delete().eq('id', id);

  Future<List<PaymentMethod>> paymentMethods() async {
    if (_uid == null) return [];
    final res = await _db
        .from('payment_methods')
        .select()
        .order('is_default', ascending: false)
        .order('created_at');
    return _rows(res).map(PaymentMethod.fromJson).toList();
  }

  Future<PaymentMethod> savePaymentMethod({
    required PaymentKind kind,
    required String label,
    String? masked,
    bool isDefault = false,
  }) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Sign in first');
    if (isDefault) {
      await _db.from('payment_methods').update({'is_default': false}).eq('user_id', uid);
    }
    final res = await _db
        .from('payment_methods')
        .insert({
          'user_id': uid,
          'kind': PaymentMethod.kindWire(kind),
          'label': label,
          'masked': masked,
          'is_default': isDefault,
        })
        .select()
        .single();
    return PaymentMethod.fromJson(res);
  }

  Future<void> deletePaymentMethod(String id) async =>
      _db.from('payment_methods').delete().eq('id', id);
}

// ───────────────────────────────────────────────────────────────────────────
// Orders
// ───────────────────────────────────────────────────────────────────────────
class OrdersRepository {
  Future<List<Order>> orders() async {
    if (_uid == null) return [];
    final res = await _db
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', ascending: false);
    return _rows(res).map(Order.fromJson).toList();
  }

  Future<Order?> order(String id) async {
    final res = await _db.from('orders').select('*, order_items(*)').eq('id', id).maybeSingle();
    return res == null ? null : Order.fromJson(res);
  }

  /// Hand the cart to Postgres and get back an order id.
  ///
  /// The only argument that touches money is the delivery fee, and even that is
  /// range-checked server side. Line prices come from the products table inside
  /// the function — there is deliberately no way from here to say what anything
  /// costs.
  Future<String> placeOrder({required String addressId, int deliveryXaf = 0}) async {
    final res = await _db.rpc('place_order', params: {
      'p_address_id': addressId,
      'p_delivery_xaf': deliveryXaf,
    });
    return res.toString();
  }

  /// Orders containing the signed-in creator's products. The RLS policy already
  /// scopes this; the query does not need a filter and must not add one, since
  /// `creator_id` lives on the items rather than the order.
  Future<List<Order>> salesForMyShop() async {
    final res = await _db
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', ascending: false);
    return _rows(res).map(Order.fromJson).toList();
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Social
// ───────────────────────────────────────────────────────────────────────────
class SocialRepository {
  Future<List<Post>> feed({int limit = 30}) async {
    final res = await _db
        .from('posts')
        .select('*, creators(*), post_likes(count), post_comments(count)')
        .order('created_at', ascending: false)
        .limit(limit);

    // Which of these the viewer has liked is a second query rather than a join:
    // `post_likes(count)` and "did *I* like it" cannot come from the same
    // aggregate, and a per-post round trip would be N+1.
    final mine = await myLikedPostIds();
    return _rows(res)
        .map((r) => Post.fromJson(r, likedByMe: mine.contains(r['id'].toString())))
        .toList();
  }

  Future<Set<String>> myLikedPostIds() async {
    if (_uid == null) return {};
    final res = await _db.from('post_likes').select('post_id');
    return _rows(res).map((r) => r['post_id'].toString()).toSet();
  }

  Future<void> like(String postId, bool on) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Sign in to like');
    if (on) {
      await _db.from('post_likes').upsert({'post_id': postId, 'user_id': uid});
    } else {
      await _db.from('post_likes').delete().eq('post_id', postId).eq('user_id', uid);
    }
  }

  Future<List<PostComment>> comments(String postId) async {
    final res = await _db
        .from('post_comments')
        .select('*, profiles(*)')
        .eq('post_id', postId)
        .order('created_at');
    return _rows(res).map(PostComment.fromJson).toList();
  }

  Future<PostComment> comment(String postId, String body) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Sign in to comment');
    final res = await _db
        .from('post_comments')
        .insert({'post_id': postId, 'user_id': uid, 'body': body})
        .select('*, profiles(*)')
        .single();
    return PostComment.fromJson(res);
  }

  Future<Set<String>> followedCreatorIds() async {
    if (_uid == null) return {};
    final res = await _db.from('follows').select('creator_id');
    return _rows(res).map((r) => r['creator_id'].toString()).toSet();
  }

  Future<List<Creator>> followedCreators() async {
    if (_uid == null) return [];
    final res = await _db
        .from('follows')
        .select('creators(*, follows(count), products(count))');
    return _rows(res)
        .map((r) => r['creators'])
        .whereType<Map>()
        .map((c) => Creator.fromJson(c.cast<String, dynamic>()))
        .toList();
  }

  Future<void> follow(String creatorId, bool on) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Sign in to follow');
    if (on) {
      await _db.from('follows').upsert({'follower_id': uid, 'creator_id': creatorId});
    } else {
      await _db.from('follows').delete().eq('follower_id', uid).eq('creator_id', creatorId);
    }
  }

  Future<void> createPost({required String creatorId, required String imageUrl, String? caption, String? productId}) async {
    await _db.from('posts').insert({
      'creator_id': creatorId,
      'image_url': imageUrl,
      'caption': caption,
      'product_id': productId,
    });
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Chat
// ───────────────────────────────────────────────────────────────────────────
class ChatRepository {
  /// Find or create the conversation with someone.
  ///
  /// Goes through `open_thread()` rather than inserting: the table requires
  /// a_id < b_id so a pair has exactly one thread, and two people tapping
  /// "message" at the same moment would otherwise race into a unique violation
  /// or, worse, two half-threads.
  Future<String> openThread(String otherUserId) async {
    final res = await _db.rpc('open_thread', params: {'p_other': otherUserId});
    return res.toString();
  }

  Future<List<ChatThread>> threads() async {
    final uid = _uid;
    if (uid == null) return [];
    final res = await _db.from('threads').select().order('last_message_at', ascending: false);

    final out = <ChatThread>[];
    for (final r in _rows(res)) {
      final otherId = r['a_id'].toString() == uid ? r['b_id'].toString() : r['a_id'].toString();
      final other = await _db.from('profiles').select().eq('id', otherId).maybeSingle();
      final last = await _db
          .from('messages')
          .select('body')
          .eq('thread_id', r['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      out.add(ChatThread(
        id: r['id'].toString(),
        otherId: otherId,
        other: other == null ? null : Profile.fromJson(other),
        lastMessageAt: DateTime.tryParse(r['last_message_at']?.toString() ?? ''),
        lastBody: last?['body']?.toString(),
      ));
    }
    return out;
  }

  Future<List<Message>> messages(String threadId) async {
    final res =
        await _db.from('messages').select().eq('thread_id', threadId).order('created_at');
    return _rows(res).map(Message.fromJson).toList();
  }

  Future<Message> send(String threadId, String body) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Sign in to send a message');
    final res = await _db
        .from('messages')
        .insert({'thread_id': threadId, 'sender_id': uid, 'body': body})
        .select()
        .single();
    return Message.fromJson(res);
  }

  /// Live messages for one thread.
  ///
  /// The socket carries the session's JWT, so RLS applies to it exactly as it
  /// does to a REST read — an unauthenticated socket is delivered nothing at
  /// all rather than erroring, which is the failure mode worth knowing about:
  /// it looks like a quiet conversation, not a broken one.
  RealtimeChannel subscribeToThread(String threadId, void Function(Message) onMessage) {
    return _db
        .channel('thread:$threadId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'thread_id',
            value: threadId,
          ),
          callback: (payload) => onMessage(Message.fromJson(payload.newRecord)),
        )
        .subscribe();
  }

  Future<void> markRead(String threadId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .from('messages')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('thread_id', threadId)
        .neq('sender_id', uid)
        .isFilter('read_at', null);
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Profile and shop
// ───────────────────────────────────────────────────────────────────────────
class ProfileRepository {
  Future<Profile?> me() async {
    final uid = _uid;
    if (uid == null) return null;
    final res = await _db.from('profiles').select().eq('id', uid).maybeSingle();
    return res == null ? null : Profile.fromJson(res);
  }

  Future<void> updateMe({String? fullName, String? avatarUrl, String? phone, String? locale, String? theme}) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('profiles').update({
      'full_name': ?fullName,
      'avatar_url': ?avatarUrl,
      'phone': ?phone,
      'locale': ?locale,
      'theme': ?theme,
    }).eq('id', uid);
  }

  /// Ask to sell. Deliberately an RPC: the profiles update policy forbids
  /// writing creator_status, so wanting to sell and being allowed to sell stay
  /// different things. Approval is a human setting it to 'approved' in SQL.
  Future<void> requestCreatorStatus() async => _db.rpc('request_creator_status');

  /// The shop the signed-in user owns, if any.
  Future<Creator?> myCreator() async {
    final uid = _uid;
    if (uid == null) return null;
    final res = await _db
        .from('creators')
        .select('*, follows(count), products(count)')
        .eq('profile_id', uid)
        .maybeSingle();
    return res == null ? null : Creator.fromJson(res);
  }

  Future<void> updateMyCreator({
    required String id,
    String? name,
    String? location,
    String? bio,
    String? avatarUrl,
    String? bannerUrl,
  }) async {
    await _db.from('creators').update({
      'name': ?name,
      'location': ?location,
      'bio': ?bio,
      'avatar_url': ?avatarUrl,
      'banner_url': ?bannerUrl,
    }).eq('id', id);
  }

  Future<Product> createProduct({
    required String creatorId,
    required String name,
    required int priceXaf,
    required String imageUrl,
    String? description,
    int? discountPct,
    List<String> tags = const [],
    String? categoryId,
    bool isNew = true,
  }) async {
    final res = await _db
        .from('products')
        .insert({
          'creator_id': creatorId,
          'name': name,
          'price_xaf': priceXaf,
          'image_url': imageUrl,
          'description': description,
          'discount_pct': discountPct,
          'tags': tags,
          'category_id': categoryId,
          'is_new': isNew,
        })
        .select(_productCols)
        .single();
    return Product.fromJson(res);
  }

  /// Delisting, not deleting. An order_item points at this row, and an order
  /// has to stay readable after the shop stops selling the thing.
  Future<void> delistProduct(String id) async =>
      _db.from('products').update({'is_active': false}).eq('id', id);
}
