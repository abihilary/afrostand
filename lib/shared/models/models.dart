/// The shapes that come back from Supabase.
///
/// Every model parses defensively: PostgREST returns `Map<String, dynamic>`
/// with nulls wherever a column is nullable or a join missed, and a cast that
/// assumes otherwise throws inside a widget build, which in Flutter means a red
/// screen rather than a handled error. Parsing is the one place that is worth
/// being pedantic.
///
/// Prices are `int` XAF throughout. The franc has no subdivision in practice,
/// and the old `String` price ('8 000') could not be summed, compared or
/// sorted - a cart total had nowhere to come from.
library;

int _asInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9-]'), '')) ?? fallback;
  return fallback;
}

String? _asString(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? _asDate(Object? v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

List<String> _asStringList(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

/// `12500` -> `12 500`. A non-breaking space, because a price must never wrap
/// across a line in the middle of the number.
String formatXaf(int amount) {
  final digits = amount.abs().toString();
  final buf = StringBuffer(amount < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}

// ─── Identity ───────────────────────────────────────────────────────────────

enum CreatorStatus { none, requested, approved, rejected }

CreatorStatus _creatorStatus(Object? v) => switch (v?.toString()) {
      'requested' => CreatorStatus.requested,
      'approved' => CreatorStatus.approved,
      'rejected' => CreatorStatus.rejected,
      _ => CreatorStatus.none,
    };

class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String locale;
  final String theme;
  final CreatorStatus creatorStatus;

  const Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.locale = 'fr',
    this.theme = 'system',
    this.creatorStatus = CreatorStatus.none,
  });

  bool get isApprovedCreator => creatorStatus == CreatorStatus.approved;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'].toString(),
        fullName: _asString(j['full_name']),
        avatarUrl: _asString(j['avatar_url']),
        phone: _asString(j['phone']),
        locale: _asString(j['locale']) ?? 'fr',
        theme: _asString(j['theme']) ?? 'system',
        creatorStatus: _creatorStatus(j['creator_status']),
      );
}

class Creator {
  final String id;
  final String? profileId;
  final String name;
  final String slug;
  final String? location;
  final String? bio;
  final String? avatarUrl;
  final String? bannerUrl;
  final int followerCount;
  final int productCount;

  const Creator({
    required this.id,
    required this.name,
    required this.slug,
    this.profileId,
    this.location,
    this.bio,
    this.avatarUrl,
    this.bannerUrl,
    this.followerCount = 0,
    this.productCount = 0,
  });

  /// Counts arrive from PostgREST as `[{count: n}]` when asked for with
  /// `follows(count)`, and are simply absent when they were not requested.
  static int _count(Object? v) {
    if (v is List && v.isNotEmpty && v.first is Map) {
      return _asInt((v.first as Map)['count']);
    }
    return _asInt(v);
  }

  factory Creator.fromJson(Map<String, dynamic> j) => Creator(
        id: j['id'].toString(),
        profileId: _asString(j['profile_id']),
        name: _asString(j['name']) ?? 'Creator',
        slug: _asString(j['slug']) ?? '',
        location: _asString(j['location']),
        bio: _asString(j['bio']),
        avatarUrl: _asString(j['avatar_url']),
        bannerUrl: _asString(j['banner_url']),
        followerCount: _count(j['follows']),
        productCount: _count(j['products']),
      );
}

// ─── Catalogue ──────────────────────────────────────────────────────────────

class ProductCategory {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? description;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.description,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> j) => ProductCategory(
        id: j['id'].toString(),
        name: _asString(j['name']) ?? '',
        slug: _asString(j['slug']) ?? '',
        imageUrl: _asString(j['image_url']),
        description: _asString(j['description']),
      );
}

class Product {
  final String id;
  final String creatorId;
  final String? categoryId;
  final String name;
  final String? description;
  final int priceXaf;
  final int? discountPct;
  final String imageUrl;
  final List<String> gallery;
  final List<String> tags;
  final bool isNew;

  /// Present when the query joined it. Null on a bare product select, which is
  /// why the card falls back to the id rather than asserting.
  final Creator? creator;

  const Product({
    required this.id,
    required this.creatorId,
    required this.name,
    required this.priceXaf,
    required this.imageUrl,
    this.categoryId,
    this.description,
    this.discountPct,
    this.gallery = const [],
    this.tags = const [],
    this.isNew = false,
    this.creator,
  });

  String get creatorName => creator?.name ?? '';
  String get priceLabel => formatXaf(priceXaf);

  /// What the buyer actually pays. Discounts are a percentage off, and the
  /// rounding happens here so the cart, the detail screen and the order all
  /// agree on the figure.
  int get effectivePriceXaf =>
      discountPct == null ? priceXaf : (priceXaf * (100 - discountPct!) / 100).round();

  String get effectivePriceLabel => formatXaf(effectivePriceXaf);
  bool get isDiscounted => discountPct != null && discountPct! > 0;
  String? get discountLabel => isDiscounted ? '-$discountPct%' : null;

  factory Product.fromJson(Map<String, dynamic> j) {
    final c = j['creators'];
    return Product(
      id: j['id'].toString(),
      creatorId: j['creator_id'].toString(),
      categoryId: _asString(j['category_id']),
      name: _asString(j['name']) ?? '',
      description: _asString(j['description']),
      priceXaf: _asInt(j['price_xaf']),
      discountPct: j['discount_pct'] == null ? null : _asInt(j['discount_pct']),
      imageUrl: _asString(j['image_url']) ?? '',
      gallery: _asStringList(j['gallery']),
      tags: _asStringList(j['tags']),
      isNew: j['is_new'] == true,
      creator: c is Map<String, dynamic> ? Creator.fromJson(c) : null,
    );
  }
}

// ─── Shopping ───────────────────────────────────────────────────────────────

class CartItem {
  final String id;
  final Product product;
  final int qty;
  final String size;
  final String color;

  const CartItem({
    required this.id,
    required this.product,
    required this.qty,
    this.size = '',
    this.color = '',
  });

  int get lineTotalXaf => product.effectivePriceXaf * qty;

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: j['id'].toString(),
        product: Product.fromJson((j['products'] as Map).cast<String, dynamic>()),
        qty: _asInt(j['qty'], 1),
        size: _asString(j['size']) ?? '',
        color: _asString(j['color']) ?? '',
      );
}

class Address {
  final String id;
  final String? label;
  final String fullName;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String country;
  final bool isDefault;

  const Address({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.city,
    this.label,
    this.line2,
    this.country = 'CM',
    this.isDefault = false,
  });

  String get oneLine => [line1, if (line2 != null) line2, city].join(', ');

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: j['id'].toString(),
        label: _asString(j['label']),
        fullName: _asString(j['full_name']) ?? '',
        phone: _asString(j['phone']) ?? '',
        line1: _asString(j['line1']) ?? '',
        line2: _asString(j['line2']),
        city: _asString(j['city']) ?? '',
        country: _asString(j['country']) ?? 'CM',
        isDefault: j['is_default'] == true,
      );
}

enum PaymentKind { mobileMoney, card, cashOnDelivery }

class PaymentMethod {
  final String id;
  final PaymentKind kind;
  final String label;
  final String? masked;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.kind,
    required this.label,
    this.masked,
    this.isDefault = false,
  });

  static PaymentKind kindFrom(Object? v) => switch (v?.toString()) {
        'card' => PaymentKind.card,
        'cash_on_delivery' => PaymentKind.cashOnDelivery,
        _ => PaymentKind.mobileMoney,
      };

  static String kindWire(PaymentKind k) => switch (k) {
        PaymentKind.card => 'card',
        PaymentKind.cashOnDelivery => 'cash_on_delivery',
        PaymentKind.mobileMoney => 'mobile_money',
      };

  factory PaymentMethod.fromJson(Map<String, dynamic> j) => PaymentMethod(
        id: j['id'].toString(),
        kind: kindFrom(j['kind']),
        label: _asString(j['label']) ?? '',
        masked: _asString(j['masked']),
        isDefault: j['is_default'] == true,
      );
}

// ─── Orders ─────────────────────────────────────────────────────────────────

enum OrderStatus { pending, paid, shipped, delivered, cancelled, refunded }

OrderStatus _orderStatus(Object? v) => switch (v?.toString()) {
      'paid' => OrderStatus.paid,
      'shipped' => OrderStatus.shipped,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      'refunded' => OrderStatus.refunded,
      _ => OrderStatus.pending,
    };

class OrderItem {
  final String id;
  final String? productId;
  /// Which shop sold this line. An order can span several shops, so a
  /// seller's revenue is the sum of their own lines, never the order total.
  final String? creatorId;
  final String name;
  final String? imageUrl;
  final int unitPriceXaf;
  final int qty;
  final String size;
  final String color;

  const OrderItem({
    required this.id,
    required this.name,
    required this.unitPriceXaf,
    required this.qty,
    this.productId,
    this.creatorId,
    this.imageUrl,
    this.size = '',
    this.color = '',
  });

  int get lineTotalXaf => unitPriceXaf * qty;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'].toString(),
        productId: _asString(j['product_id']),
        creatorId: _asString(j['creator_id']),
        name: _asString(j['name']) ?? '',
        imageUrl: _asString(j['image_url']),
        unitPriceXaf: _asInt(j['unit_price_xaf']),
        qty: _asInt(j['qty'], 1),
        size: _asString(j['size']) ?? '',
        color: _asString(j['color']) ?? '',
      );
}

class Order {
  final String id;
  final String code;
  final OrderStatus status;
  final int subtotalXaf;
  final int deliveryXaf;
  final int totalXaf;
  final Map<String, dynamic> shipTo;
  final DateTime? createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.code,
    required this.status,
    required this.subtotalXaf,
    required this.deliveryXaf,
    required this.totalXaf,
    this.shipTo = const {},
    this.createdAt,
    this.items = const [],
  });

  int get itemCount => items.fold(0, (s, i) => s + i.qty);
  String get totalLabel => formatXaf(totalXaf);

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'].toString(),
        code: _asString(j['code']) ?? '',
        status: _orderStatus(j['status']),
        subtotalXaf: _asInt(j['subtotal_xaf']),
        deliveryXaf: _asInt(j['delivery_xaf']),
        totalXaf: _asInt(j['total_xaf']),
        shipTo: (j['ship_to'] as Map?)?.cast<String, dynamic>() ?? const {},
        createdAt: _asDate(j['created_at']),
        items: (j['order_items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => OrderItem.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

// ─── Social ─────────────────────────────────────────────────────────────────

class Post {
  final String id;
  final String creatorId;
  final String? productId;
  final String imageUrl;
  final String? caption;
  final DateTime? createdAt;
  final Creator? creator;
  final int likeCount;
  final int commentCount;

  /// Whether *this* viewer has liked it. Not a column — derived from the
  /// viewer's own likes, because a like is per-person.
  final bool likedByMe;

  const Post({
    required this.id,
    required this.creatorId,
    required this.imageUrl,
    this.productId,
    this.caption,
    this.createdAt,
    this.creator,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
  });

  Post copyWith({int? likeCount, bool? likedByMe, int? commentCount}) => Post(
        id: id,
        creatorId: creatorId,
        productId: productId,
        imageUrl: imageUrl,
        caption: caption,
        createdAt: createdAt,
        creator: creator,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        likedByMe: likedByMe ?? this.likedByMe,
      );

  factory Post.fromJson(Map<String, dynamic> j, {bool likedByMe = false}) {
    final c = j['creators'];
    return Post(
      id: j['id'].toString(),
      creatorId: j['creator_id'].toString(),
      productId: _asString(j['product_id']),
      imageUrl: _asString(j['image_url']) ?? '',
      caption: _asString(j['caption']),
      createdAt: _asDate(j['created_at']),
      creator: c is Map<String, dynamic> ? Creator.fromJson(c) : null,
      likeCount: Creator._count(j['post_likes']),
      commentCount: Creator._count(j['post_comments']),
      likedByMe: likedByMe,
    );
  }
}

class PostComment {
  final String id;
  final String userId;
  final String body;
  final DateTime? createdAt;
  final Profile? author;

  const PostComment({
    required this.id,
    required this.userId,
    required this.body,
    this.createdAt,
    this.author,
  });

  factory PostComment.fromJson(Map<String, dynamic> j) {
    final p = j['profiles'];
    return PostComment(
      id: j['id'].toString(),
      userId: j['user_id'].toString(),
      body: _asString(j['body']) ?? '',
      createdAt: _asDate(j['created_at']),
      author: p is Map<String, dynamic> ? Profile.fromJson(p) : null,
    );
  }
}

// ─── Chat ───────────────────────────────────────────────────────────────────

class ChatThread {
  final String id;
  final String otherId;
  final Profile? other;
  final DateTime? lastMessageAt;
  final String? lastBody;
  final int unread;

  const ChatThread({
    required this.id,
    required this.otherId,
    this.other,
    this.lastMessageAt,
    this.lastBody,
    this.unread = 0,
  });
}

class Message {
  final String id;
  final String threadId;
  final String senderId;
  final String body;
  final DateTime? createdAt;
  final DateTime? readAt;

  const Message({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    this.createdAt,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'].toString(),
        threadId: j['thread_id'].toString(),
        senderId: j['sender_id'].toString(),
        body: _asString(j['body']) ?? '',
        createdAt: _asDate(j['created_at']),
        readAt: _asDate(j['read_at']),
      );
}

/// A banner plus the items under it. Used by the home screen to keep the two
/// together while the selected collection changes.
class CollectionData {
  final String bannerTitle;
  final String bannerSubtitle;
  final String bannerImage;
  final List<Product> products;

  const CollectionData({
    required this.bannerTitle,
    required this.bannerSubtitle,
    required this.bannerImage,
    required this.products,
  });
}
