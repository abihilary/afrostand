import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/auth_provider.dart';
import '../core/providers/settings_provider.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/otp/otp_screen.dart';
import '../features/auth/register/register_screen.dart';
import '../features/auth/welcome/welcome_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/categories/category_feed_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/social/social_swipe_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/threads_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/payments/payment_screen.dart';
import '../features/checkout/order_success_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/orders_screen.dart';
import '../features/profile/wishlist_screen.dart';
import '../features/profile/addresses_screen.dart';
import '../features/profile/payment_methods_screen.dart';
import '../features/profile/followed_creators_screen.dart';
import '../features/creators/creator_profile_screen.dart';
import '../features/creators/creator_dashboard_screen.dart';
import '../features/creators/add_product_screen.dart';
import '../features/creators/edit_creator_profile_screen.dart';
import '../features/search/search_filter_screen.dart';
import '../shared/widgets/main_wrapper.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';

  // Main tabs
  static const home = '/home';
  static const search = '/search';
  static const creators = '/creators';
  static const cart = '/cart';
  static const profile = '/profile';

  static const checkout = '/checkout';
  static const payment = '/payment';
  static const orderSuccess = '/order-success';
  static const threads = '/messages';
  static const creatorDashboard = '/creator-dashboard';
  static const addProduct = '/add-product';
  static const editCreatorProfile = '/edit-creator-profile';
  static const searchFilter = '/search-filter';

  // Profile sub-routes
  static const orders = '/orders';
  static const wishlist = '/wishlist';
  static const addresses = '/addresses';
  static const paymentMethods = '/payment-methods';
  static const followedCreators = '/followed-creators';

  // Parameterised. These used to take nothing at all, which is why the product
  // screen rendered the same hardcoded image whatever you tapped.
  static String productDetail(String id) => '/home/product/$id';
  static String categoryFeed(String slug) => '/home/category/$slug';
  static String creatorProfile(String id) => '/creator/$id';
  static String chat(String threadId) => '/messages/$threadId';
}

/// Routes anybody may see, signed in or not.
///
/// Browsing is public on purpose, and it matches the database: the catalogue
/// has a `using (true)` select policy. Making people sign up before they can
/// see a single product is how a young marketplace gets no customers.
/// Everything that reads or writes somebody's own rows is not on this list.
const _publicPrefixes = <String>[
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.otp,
  AppRoutes.home,
  AppRoutes.search,
  AppRoutes.creators,
  '/creator/',
];

bool _isPublic(String location) =>
    _publicPrefixes.any((p) => location == p || location.startsWith(p));

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Rebuilds the router's redirect whenever auth or settings change.
///
/// GoRouter only re-evaluates `redirect` when this notifies, so without it
/// signing in leaves you sitting on the login screen and signing out leaves a
/// signed-out user looking at a cart.
class _Refresh extends ChangeNotifier {
  _Refresh(List<Listenable> sources) {
    for (final s in sources) {
      s.addListener(notifyListeners);
      _sources.add(s);
    }
  }
  final _sources = <Listenable>[];

  @override
  void dispose() {
    for (final s in _sources) {
      s.removeListener(notifyListeners);
    }
    super.dispose();
  }
}

GoRouter createRouter({required AppSettings settings, required AuthProvider auth}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    navigatorKey: _rootNavigatorKey,
    refreshListenable: _Refresh([settings, auth]),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Preferences are still being read off disk. Holding on the splash is
      // better than routing on a default that is about to change.
      if (!settings.isReady) return loc == AppRoutes.splash ? null : AppRoutes.splash;

      final signedIn = auth.isAuthenticated;
      final onSplash = loc == AppRoutes.splash;

      if (!settings.hasSeenOnboarding) {
        return loc == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      // Onboarding is done. The splash has nothing left to say.
      if (onSplash) return signedIn ? AppRoutes.home : AppRoutes.welcome;

      // Already signed in: the auth screens would be a dead end.
      if (signedIn &&
          (loc == AppRoutes.login ||
              loc == AppRoutes.register ||
              loc == AppRoutes.welcome ||
              loc == AppRoutes.onboarding)) {
        return AppRoutes.home;
      }

      if (!signedIn && !_isPublic(loc)) return AppRoutes.login;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (c, s) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.login, builder: (c, s) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (c, s) => const RegisterScreen()),
      GoRoute(path: AppRoutes.otp, builder: (c, s) => const OtpScreen()),

      GoRoute(path: AppRoutes.checkout, builder: (c, s) => const CheckoutScreen()),
      GoRoute(path: AppRoutes.payment, builder: (c, s) => const PaymentScreen()),
      GoRoute(path: AppRoutes.orderSuccess, builder: (c, s) => const OrderSuccessScreen()),

      GoRoute(
        path: AppRoutes.threads,
        builder: (c, s) => const ThreadsScreen(),
        routes: [
          GoRoute(
            path: ':threadId',
            builder: (c, s) => ChatScreen(threadId: s.pathParameters['threadId']!),
          ),
        ],
      ),

      GoRoute(
        path: '/creator/:id',
        builder: (c, s) => CreatorProfileScreen(creatorId: s.pathParameters['id']!),
      ),

      GoRoute(path: AppRoutes.creatorDashboard, builder: (c, s) => const CreatorDashboardScreen()),
      GoRoute(path: AppRoutes.addProduct, builder: (c, s) => const AddProductScreen()),
      GoRoute(path: AppRoutes.editCreatorProfile, builder: (c, s) => const EditCreatorProfileScreen()),
      GoRoute(path: AppRoutes.searchFilter, builder: (c, s) => const SearchFilterScreen()),

      GoRoute(path: AppRoutes.orders, builder: (c, s) => const OrdersScreen()),
      GoRoute(path: AppRoutes.wishlist, builder: (c, s) => const WishlistScreen()),
      GoRoute(path: AppRoutes.addresses, builder: (c, s) => const AddressesScreen()),
      GoRoute(path: AppRoutes.paymentMethods, builder: (c, s) => const PaymentMethodsScreen()),
      GoRoute(path: AppRoutes.followedCreators, builder: (c, s) => const FollowedCreatorsScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainWrapper(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (c, s) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'product/:id',
                    builder: (c, s) => ProductDetailScreen(productId: s.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'category/:slug',
                    builder: (c, s) => CategoryFeedScreen(slug: s.pathParameters['slug']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.search, builder: (c, s) => const SearchFilterScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.creators, builder: (c, s) => const SocialSwipeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.cart, builder: (c, s) => const CartScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.profile, builder: (c, s) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
}
