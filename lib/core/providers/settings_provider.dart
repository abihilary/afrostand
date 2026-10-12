import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme, language, and whether onboarding has been seen.
///
/// Previously all of this lived in memory, so the app forgot the chosen
/// language on every launch and fell back to the phone's locale — which on a
/// phone set to English silently undid a French speaker's choice, every time.
///
/// Stored locally first and mirrored to `profiles` when signed in. Local is
/// the source of truth for rendering: the app has to pick a theme before it
/// knows whether anybody is signed in, and waiting on the network to decide
/// what colour to paint would mean a flash of the wrong one on every start.
class AppSettings extends ChangeNotifier {
  static const _kTheme = 'settings.theme';
  static const _kLocale = 'settings.locale';
  static const _kOnboarded = 'settings.onboarded';

  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = _systemLocale();
  bool _onboarded = false;
  bool _ready = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get hasSeenOnboarding => _onboarded;

  /// False until the stored values are read. The router waits on this, because
  /// routing on a default that is about to change sends people to onboarding
  /// they already completed.
  bool get isReady => _ready;

  static Locale _systemLocale() =>
      ui.PlatformDispatcher.instance.locale.languageCode == 'en'
          ? const Locale('en')
          : const Locale('fr'); // French first — this is the primary market.

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final t = _prefs?.getString(_kTheme);
    _themeMode = switch (t) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final l = _prefs?.getString(_kLocale);
    if (l == 'en' || l == 'fr') _locale = Locale(l!);
    _onboarded = _prefs?.getBool(_kOnboarded) ?? false;
    _ready = true;
    notifyListeners();
  }

  /// Applied to what is on screen whether or not the write lands. A failed
  /// disk write is not a reason to refuse somebody a dark theme.
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _prefs?.setString(_kTheme, mode.name);
  }

  void toggleTheme(bool isDark) => setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
    _prefs?.setString(_kLocale, locale.languageCode);
  }

  void markOnboarded() {
    if (_onboarded) return;
    _onboarded = true;
    notifyListeners();
    _prefs?.setBool(_kOnboarded, true);
  }

  /// Adopt what the account remembers, on sign-in. Only moves things that were
  /// actually stored — an account with no preference must not drag a signed-in
  /// user back to the default and undo a choice they made moments ago.
  void adoptFromProfile({String? locale, String? theme}) {
    if (locale == 'en' || locale == 'fr') setLocale(Locale(locale!));
    if (theme == 'light' || theme == 'dark' || theme == 'system') {
      setThemeMode(switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      });
    }
  }
}
