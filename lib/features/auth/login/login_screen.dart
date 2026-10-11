import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../../../core/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(email: email, password: password);

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Authentication failed')),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address first')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(email);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Failed to send reset email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

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
              AppLocalizations.of(context)!.welcomeBack,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.loginSubtitle,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 32),

            Text(
              AppLocalizations.of(context)!.emailOrPhone,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'toi@exemple.com',
              ),
            ),

            const SizedBox(height: 24),

            Text(
              AppLocalizations.of(context)!.password,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: '••••••••',
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        activeColor: AppColors.orange,
                        checkColor: AppColors.dark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.rememberMe, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                TextButton(
                  onPressed: _handleForgotPassword,
                  child: Text(
                    AppLocalizations.of(context)!.forgotPassword,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: isDark ? AppColors.orange : AppColors.dark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _handleLogin,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(AppLocalizations.of(context)!.signIn),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: TextButton(
                onPressed: () => context.push(AppRoutes.register),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                    children: [
                      TextSpan(text: AppLocalizations.of(context)!.newHere),
                      TextSpan(
                        text: AppLocalizations.of(context)!.createAccount,
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
