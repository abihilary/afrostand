import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../generated/l10n/app_localizations.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.dark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.orderConfirmed,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.orderPrep('Aminata', 'AFR-2025-8821', 'demain 14h à Almadies'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(image: NetworkImage(AppAssets.model1), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Boubou Wax Royal x2', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          Text('Livraison Express • Wave payé', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.bold)),
                          Text('22 000 FCFA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home), // In real app, go to orders
                child: Text(l10n.trackOrder),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l10n.continueShopping),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
