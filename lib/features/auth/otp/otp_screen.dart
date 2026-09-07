import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Vérifie ton numéro',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Code envoyé au +221 77 123 45 67',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),

            const SizedBox(height: 48),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _otpBox('5'),
                _otpBox('2'),
                _otpBox('8'),
                _otpBox(''),
              ],
            ),

            const SizedBox(height: 48),

            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Vérifier & Continuer'),
            ),

            const SizedBox(height: 24),

            Center(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                  children: [
                    TextSpan(text: 'Pas reçu? '),
                    TextSpan(
                      text: 'Renvoyer (28s)',
                      style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: AppColors.dark),
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

  Widget _otpBox(String text) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
