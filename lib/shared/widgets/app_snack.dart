import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes.dart';
import '../../generated/l10n/app_localizations.dart';

/// Turn a thrown object into something a shopper can read.
///
/// Fifteen places did `SnackBar(content: Text('$e'))`, which put
/// `AuthException(message: Sign in to use the cart, statusCode: null, code:
/// null)` in front of somebody trying to buy a dress. The message inside was
/// right; everything around it was for us, not for them.
String humanError(Object e, AppLocalizations l10n) {
  if (e is AuthException) return e.message;
  if (e is StorageException) return e.message;
  if (e is PostgrestException) {
    // A policy refusal is not a bug report. 42501 is insufficient_privilege;
    // PostgREST also sends the RLS text through on an insert it blocks.
    if (e.code == '42501' || e.message.contains('row-level security')) {
      return l10n.errorNotAllowed;
    }
    return e.message;
  }
  if (e is SocketException || e is TimeoutException || e is HandshakeException) {
    return l10n.errorOffline;
  }
  return l10n.somethingWrong;
}

/// Show a failure, and where there is an obvious next step, offer it.
void showError(BuildContext context, Object e) {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final isAuth = e is AuthException;

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(humanError(e, l10n)),
    behavior: SnackBarBehavior.floating,
    action: isAuth
        // "Sign in to use the cart" with no way to sign in from where you are
        // standing is only half a message.
        ? SnackBarAction(
            label: l10n.signIn,
            onPressed: () => router.push(AppRoutes.login),
          )
        : null,
  ));
}
