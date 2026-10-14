import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

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
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.welcome),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.verifyNumber,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)!.codeSentTo} +221 77 123 45 67',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
            ),

            const SizedBox(height: 48),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _otpBox(context, '5'),
                _otpBox(context, '2'),
                _otpBox(context, '8'),
                _otpBox(context, ''),
              ],
            ),

            const SizedBox(height: 48),

            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text(AppLocalizations.of(context)!.verifyAndContinue),
            ),

            const SizedBox(height: 24),

            Center(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                  children: [
                    TextSpan(text: AppLocalizations.of(context)!.didntReceive),
                    TextSpan(
                      text: AppLocalizations.of(context)!.resend,
                      style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: isDark ? AppColors.orange : AppColors.dark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.dark,
          ),
        ),
      ),
    );
  }
}
