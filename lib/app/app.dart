import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../generated/l10n/app_localizations.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/session.dart';

import 'routes.dart';
import 'theme.dart';

/// Stateful so the router is built exactly once.
///
/// A GoRouter rebuilt on every frame loses its navigation stack, which shows
/// up as the back button doing nothing and deep links bouncing to the start.
class AfrostandApp extends StatefulWidget {
  const AfrostandApp({super.key});

  @override
  State<AfrostandApp> createState() => _AfrostandAppState();
}

class _AfrostandAppState extends State<AfrostandApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    _router ??= createRouter(settings: settings, auth: context.read<AuthProvider>());

    return SessionLoader(
      child: MaterialApp.router(
        title: 'AFROSTAND',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.themeMode,
        locale: settings.locale,
        routerConfig: _router!,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('fr')],
      ),
    );
  }
}
