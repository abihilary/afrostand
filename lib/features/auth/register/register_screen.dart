import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.registerTitle,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.dark,
              ),
            ),
            const SizedBox(height: 32),

            TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.fullName,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.email,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.password,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () => context.push(AppRoutes.otp),
              child: Text(AppLocalizations.of(context)!.continueBtn),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                AppLocalizations.of(context)!.otpNotice,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.black26),
              ),
            ),

            const SizedBox(height: 48),

            Center(
              child: TextButton(
                onPressed: () => context.push(AppRoutes.login),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                    children: [
                      TextSpan(text: AppLocalizations.of(context)!.alreadyHaveAccount),
                      TextSpan(
                        text: AppLocalizations.of(context)!.signIn,
                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.orange : AppColors.dark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
