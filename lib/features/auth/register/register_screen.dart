import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
            const Text(
              'Créer un compte',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),

            const TextField(
              decoration: InputDecoration(
                hintText: 'Nom complet',
              ),
            ),

            const SizedBox(height: 16),

            const TextField(
              decoration: InputDecoration(
                hintText: 'Email',
              ),
            ),

            const SizedBox(height: 16),

            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Mot de passe',
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () => context.push(AppRoutes.otp),
              child: const Text('Continuer'),
            ),

            const SizedBox(height: 16),

            const Center(
              child: Text(
                'Tu recevras un code OTP par SMS',
                style: TextStyle(fontSize: 11, color: Colors.black26),
              ),
            ),

            const SizedBox(height: 48),

            Center(
              child: TextButton(
                onPressed: () => context.push(AppRoutes.login),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                    children: [
                      TextSpan(text: 'Déjà un compte? '),
                      TextSpan(
                        text: 'Se connecter',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
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
