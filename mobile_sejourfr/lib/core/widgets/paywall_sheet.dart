import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';
import 'tcf_paywall.dart';

/// Nombre de questions en mode démo (sans abonnement) — partagé entre les
/// différents écrans qui démarrent un attempt d'entraînement.
const int kDemoBatchSize = 20;

/// Nombre de questions par session premium.
const int kInitialBatchSize = 30;

/// Sheet bottom modal d'upsell, affiché quand un appel renvoie un 403
/// "demo limit reached" ou quand l'utilisateur tap un module verrouillé.
class PaywallSheet extends StatelessWidget {
  const PaywallSheet({super.key, this.demoBatchSize = kDemoBatchSize});

  final int demoBatchSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.blue, AppColors.blueDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Continuez en illimité',
                textAlign: TextAlign.center,
                style: AppFonts.fraunces(size: 24, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'La démo s\'arrête à $demoBatchSize questions. Activez l\'accès complet sur le web pour profiter de tous les thèmes et de l\'entraînement illimité.',
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Gérer mon accès sur le web',
                icon: Icons.open_in_new_rounded,
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openSubscriptionWeb(context);
                },
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Plus tard',
                  style: AppFonts.jakarta(size: 13, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showPaywallSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (_) => const PaywallSheet(),
  );
}
