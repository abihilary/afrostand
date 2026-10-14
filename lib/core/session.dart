import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/profile_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/social_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/chat_provider.dart';

/// Loads what belongs to the signed-in person, and drops it when they leave.
///
/// Sitting in one place rather than in each screen's initState because the
/// important half is the *clearing*. A cart, an address or a conversation left
/// in a provider after sign-out stays on screen for whoever signs in next on
/// that phone — a shared phone is the normal case here, not the edge case.
class SessionLoader extends StatefulWidget {
  const SessionLoader({super.key, required this.child});
  final Widget child;

  @override
  State<SessionLoader> createState() => _SessionLoaderState();
}

class _SessionLoaderState extends State<SessionLoader> {
  StreamSubscription<AuthState>? _sub;
  String? _loadedFor;

  @override
  void initState() {
    super.initState();
    // The catalogue is public, so it loads once and does not depend on anyone
    // being signed in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CatalogProvider>().load();
      _apply(Supabase.instance.client.auth.currentUser?.id);
    });

    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      _apply(state.session?.user.id);
    });
  }

  void _apply(String? uid) {
    // Guarded on the id rather than fired on every event: onAuthStateChange
    // also emits on token refresh, which happens roughly hourly and would
    // otherwise re-fetch the whole account each time.
    if (uid == _loadedFor) return;
    _loadedFor = uid;
    if (!mounted) return;

    final profile = context.read<ProfileProvider>();
    final shop = context.read<ShopProvider>();
    final orders = context.read<OrdersProvider>();
    final social = context.read<SocialProvider>();
    final chat = context.read<ChatProvider>();

    if (uid == null) {
      profile.clearLocal();
      shop.clearLocal();
      orders.clearLocal();
      social.clearLocal();
      chat.clearLocal();
      return;
    }

    () async {
      await profile.load();
      if (!mounted) return;
      // The account's remembered language and theme win over the device
      // default once we know whose account it is.
      final me = profile.me;
      if (me != null) {
        context.read<AppSettings>().adoptFromProfile(locale: me.locale, theme: me.theme);
      }
      await Future.wait([shop.load(), orders.load(), social.loadFeed(), chat.load()]);
    }();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
