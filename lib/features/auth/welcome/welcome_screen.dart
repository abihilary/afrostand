import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  color: AppColors.sand,
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
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
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
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: Text(AppLocalizations.of(context)!.createAccount),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.login),
                    child: Text(AppLocalizations.of(context)!.signIn),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.black.withOpacity(0.1))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppLocalizations.of(context)!.or,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black26),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.black.withOpacity(0.1))),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _socialButton(
                          icon: 'G',
                          label: 'Google',
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _socialButton(
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black26,
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
    required String icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
    Color? textColor,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color == null ? Colors.white : Colors.white,
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
              color: textColor ?? AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
