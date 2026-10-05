import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login/login_screen.dart';
import '../features/auth/otp/otp_screen.dart';
import '../features/auth/register/register_screen.dart';
import '../features/auth/welcome/welcome_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/categories/category_feed_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/products/product_masonry_screen.dart';
import '../features/social/social_swipe_screen.dart';
import '../features/chat/chat_screen.dart';
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
import '../features/search/search_filter_screen.dart';
import '../shared/widgets/main_wrapper.dart';
import 'constants.dart';


class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  
  // Main Tabs
  static const home = '/home';
  static const search = '/search';
  static const creators = '/creators';
  static const cart = '/cart';
  static const profile = '/profile';
  
  static const checkout = '/checkout';
  static const payment = '/payment';
  static const orderSuccess = '/order-success';
  static const chat = '/chat';
  static const creatorProfile = '/creator-profile';
  static const searchFilter = '/search-filter';
  
  // Profile sub-routes
  static const orders = '/orders';
  static const wishlist = '/wishlist';
  static const addresses = '/addresses';
  static const paymentMethods = '/payment-methods';
  static const followedCreators = '/followed-creators';
  
  // Sub routes
  static const productDetail = 'product-detail';
  static const categoryFeed = 'category';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: AppRoutes.splash,
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      builder: (context, state) => const OtpScreen(),
    ),
    GoRoute(
      path: AppRoutes.checkout,
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: AppRoutes.payment,
      builder: (context, state) => const PaymentScreen(),
    ),
    GoRoute(
      path: AppRoutes.orderSuccess,
      builder: (context, state) => const OrderSuccessScreen(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: AppRoutes.creatorProfile,
      builder: (context, state) => const CreatorProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.searchFilter,
      builder: (context, state) => const SearchFilterScreen(),
    ),
    GoRoute(
      path: AppRoutes.orders,
      builder: (context, state) => const OrdersScreen(),
    ),
    GoRoute(
      path: AppRoutes.wishlist,
      builder: (context, state) => const WishlistScreen(),
    ),
    GoRoute(
      path: AppRoutes.addresses,
      builder: (context, state) => const AddressesScreen(),
    ),
    GoRoute(
      path: AppRoutes.paymentMethods,
      builder: (context, state) => const PaymentMethodsScreen(),
    ),
    GoRoute(
      path: AppRoutes.followedCreators,
      builder: (context, state) => const FollowedCreatorsScreen(),
    ),
    
    // Main App Shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainWrapper(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: AppRoutes.productDetail,
                  builder: (context, state) => const ProductDetailScreen(),
                ),
                GoRoute(
                  path: AppRoutes.categoryFeed,
                  builder: (context, state) {
                    final title = state.uri.queryParameters['title'] ?? 'Collection';
                    final imageUrl = state.uri.queryParameters['image'] ?? AppAssets.model1;
                    return CategoryFeedScreen(
                      title: title,
                      imageUrl: imageUrl,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.search,
              builder: (context, state) => const SearchFilterScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.creators,
              builder: (context, state) => const SocialSwipeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.cart,
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
