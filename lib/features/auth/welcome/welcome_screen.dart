import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/animated_pressable.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1510) : AppColors.sand,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    '👋',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.dark,
                    height: 0.95,
                    letterSpacing: -1,
                  ),
                  children: [
                    TextSpan(text: AppLocalizations.of(context)!.welcomeTitle),
                    const TextSpan(
                      text: 'Afrostand',
                      style: TextStyle(color: AppColors.orange),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                AppLocalizations.of(context)!.welcomeSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              Column(
                children: [
                  AnimatedPressable(
                    onTap: () => context.push(AppRoutes.register),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.orange : AppColors.dark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context)!.createAccount,
                        style: TextStyle(color: isDark ? AppColors.dark : Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  AnimatedPressable(
                    onTap: () => context.push(AppRoutes.login),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context)!.signIn,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.dark, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: Divider(color: theme.dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppLocalizations.of(context)!.or,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : Colors.black26),
                        ),
                      ),
                      Expanded(child: Divider(color: theme.dividerColor)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _socialButton(
                          context: context,
                          icon: 'G',
                          label: 'Google',
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _socialButton(
                          context: context,
                          icon: 'f',
                          label: 'Facebook',
                          color: const Color(0xFF1877F2),
                          textColor: Colors.white,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              Center(
                child: Text(
                  AppLocalizations.of(context)!.termsAgreement,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedPressable(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color == null ? Theme.of(context).dividerColor : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withOpacity(0.1), width: 0.5),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color ?? AppColors.dark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: textColor ?? (isDark ? Colors.white : AppColors.dark),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
