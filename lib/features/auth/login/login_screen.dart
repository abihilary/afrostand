import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.loginSubtitle,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 32),

            Text(
              AppLocalizations.of(context)!.emailOrPhone,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 8),
            const TextField(
              decoration: InputDecoration(
                hintText: 'toi@exemple.com',
              ),
            ),

            const SizedBox(height: 24),

            Text(
              AppLocalizations.of(context)!.password,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 8),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.rememberMe, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    AppLocalizations.of(context)!.forgotPassword,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text(AppLocalizations.of(context)!.signIn),
            ),

            const SizedBox(height: 24),

            Center(
              child: TextButton(
                onPressed: () => context.push(AppRoutes.register),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                    children: [
                      TextSpan(text: AppLocalizations.of(context)!.newHere),
                      TextSpan(
                        text: AppLocalizations.of(context)!.createAccount,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
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
