import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/constants.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/catalog_provider.dart';
import 'core/providers/shop_provider.dart';
import 'core/providers/orders_provider.dart';
import 'core/providers/social_provider.dart';
import 'core/providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Read before the first frame. The router decides between onboarding, the
  // welcome screen and the app from these, and deciding on a default that is
  // about to be replaced sends people somewhere they did not ask to go.
  final settings = AppSettings();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const AfrostandApp(),
    ),
  );
}
