import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AFROSTAND'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'AFRICAN FASHION'**
  String get tagline;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'LOADING...'**
  String get loading;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @startAdventure.
  ///
  /// In en, this message translates to:
  /// **'Start the adventure'**
  String get startAdventure;

  /// No description provided for @discoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover a world of shopping with '**
  String get discoveryTitle;

  /// No description provided for @discoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local creators, unique pieces, handmade with love.'**
  String get discoverySubtitle;

  /// No description provided for @socialShopping.
  ///
  /// In en, this message translates to:
  /// **'SOCIAL SHOPPING'**
  String get socialShopping;

  /// No description provided for @socialTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping is better with friends'**
  String get socialTitle;

  /// No description provided for @socialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your looks, ask your friends\' advice, shop together in real time.'**
  String get socialSubtitle;

  /// No description provided for @commentAminata.
  ///
  /// In en, this message translates to:
  /// **'I love this boubou! 😍'**
  String get commentAminata;

  /// No description provided for @messageJames.
  ///
  /// In en, this message translates to:
  /// **'This look suits you so well!'**
  String get messageJames;

  /// No description provided for @marketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'African Print\nMarketplace'**
  String get marketplaceTitle;

  /// No description provided for @marketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Authentic, traceable, sustainable. Each piece tells a story of craftsmanship.'**
  String get marketplaceSubtitle;

  /// No description provided for @handmade.
  ///
  /// In en, this message translates to:
  /// **'Handmade'**
  String get handmade;

  /// No description provided for @creators.
  ///
  /// In en, this message translates to:
  /// **'Creators'**
  String get creators;

  /// No description provided for @pieces.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get pieces;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\n'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the community celebrating contemporary African fashion.'**
  String get welcomeSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you accept our T&Cs & Privacy Policy'**
  String get termsAgreement;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to find your favorites.'**
  String get loginSubtitle;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'EMAIL OR PHONE'**
  String get emailOrPhone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here? '**
  String get newHere;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get registerTitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @otpNotice.
  ///
  /// In en, this message translates to:
  /// **'You will receive an OTP code by SMS'**
  String get otpNotice;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @verifyNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get verifyNumber;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to'**
  String get codeSentTo;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// No description provided for @didntReceive.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive it? '**
  String get didntReceive;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend (28s)'**
  String get resend;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'GOOD MORNING'**
  String get goodMorning;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// No description provided for @sustainable.
  ///
  /// In en, this message translates to:
  /// **'Sustainable'**
  String get sustainable;

  /// No description provided for @gift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get gift;

  /// No description provided for @exclusive.
  ///
  /// In en, this message translates to:
  /// **'AFROSTAND EXCLUSIVE'**
  String get exclusive;

  /// No description provided for @newCollection.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get newCollection;

  /// No description provided for @collectionDesc.
  ///
  /// In en, this message translates to:
  /// **'-30% for the first 100 orders'**
  String get collectionDesc;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'SEE ALL'**
  String get seeAll;

  /// No description provided for @featuredProducts.
  ///
  /// In en, this message translates to:
  /// **'Featured Products'**
  String get featuredProducts;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navCreators.
  ///
  /// In en, this message translates to:
  /// **'Creators'**
  String get navCreators;

  /// No description provided for @navCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get navCart;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @panier.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get panier;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'SUMMARY'**
  String get summary;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place order'**
  String get placeOrder;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'SIZE'**
  String get size;

  /// No description provided for @colorPattern.
  ///
  /// In en, this message translates to:
  /// **'COLOR — PATTERN'**
  String get colorPattern;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get addedToCart;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get buyNow;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'followers'**
  String get followers;

  /// No description provided for @respondsIn.
  ///
  /// In en, this message translates to:
  /// **'Responds in'**
  String get respondsIn;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @swipeAndSlay.
  ///
  /// In en, this message translates to:
  /// **'Swipe & Slay'**
  String get swipeAndSlay;

  /// No description provided for @commentedOnLook.
  ///
  /// In en, this message translates to:
  /// **'shared a look'**
  String get commentedOnLook;

  /// No description provided for @adore.
  ///
  /// In en, this message translates to:
  /// **'Adore 🔥'**
  String get adore;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @respondsFast.
  ///
  /// In en, this message translates to:
  /// **'Responds fast'**
  String get respondsFast;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get writeMessage;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Address & Delivery'**
  String get checkoutTitle;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping address'**
  String get shippingAddress;

  /// No description provided for @modify.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get modify;

  /// No description provided for @deliveryOptions.
  ///
  /// In en, this message translates to:
  /// **'Delivery options'**
  String get deliveryOptions;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentTitle;

  /// No description provided for @totalToPay.
  ///
  /// In en, this message translates to:
  /// **'Total to pay'**
  String get totalToPay;

  /// No description provided for @mobileMoney.
  ///
  /// In en, this message translates to:
  /// **'MOBILE MONEY'**
  String get mobileMoney;

  /// No description provided for @bankCard.
  ///
  /// In en, this message translates to:
  /// **'BANK CARD'**
  String get bankCard;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order confirmed! 🥳'**
  String get orderConfirmed;

  /// No description provided for @orderPrep.
  ///
  /// In en, this message translates to:
  /// **'Thank you {name}! Your order #{orderId} is being prepared. Delivery scheduled for {deliveryTime}.'**
  String orderPrep(String name, String orderId, String deliveryTime);

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track my order'**
  String get trackOrder;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping'**
  String get continueShopping;

  /// No description provided for @memberGold.
  ///
  /// In en, this message translates to:
  /// **'GOLD MEMBER'**
  String get memberGold;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get points;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @followedCreators.
  ///
  /// In en, this message translates to:
  /// **'Followed Creators'**
  String get followedCreators;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get myOrders;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get inProgress;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'FILTERS'**
  String get filters;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @since.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get since;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Boubou, wax, Dakar...'**
  String get searchPlaceholder;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
