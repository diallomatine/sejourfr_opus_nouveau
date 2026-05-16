import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// URL de la page de paiement web. Le paiement Stripe (Payment Links) se
/// fait uniquement sur le web (commission Apple/Google évitée).
const String tcfPaywallUrl = 'https://sejourfr.fr/paiement';

/// Carte « TCF réservé à l'offre Intégral », à afficher en plein écran à la
/// place du contenu TCF quand l'utilisateur n'a que l'accès civique
/// (ou aucun plan actif).
class TcfPaywallCard extends StatelessWidget {
  const TcfPaywallCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline,
                    color: AppColors.blue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'TCF — accès Intégral requis',
                  style: AppFonts.fraunces(
                    size: 18,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Votre formule actuelle ne couvre pas le module TCF (compréhension écrite, '
            'compréhension orale et structure de la langue).',
            style: AppFonts.jakarta(
              size: 14,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Passez à la formule Intégral pour 3 mois d\'accès complet à Civique + TCF.',
            style: AppFonts.jakarta(
              size: 14,
              color: AppColors.ink2,
              weight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _TcfPaywallCopyButton(),
        ],
      ),
    );
  }
}

/// Bottom sheet qui affiche le paywall TCF. Utilisé quand l'utilisateur tente
/// de basculer en TCF depuis l'interface (ex : ModuleSwitch).
Future<void> showTcfPaywallSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline,
                    color: AppColors.blue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'TCF — accès Intégral requis',
                  style: AppFonts.fraunces(
                    size: 18,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Votre formule actuelle ne couvre pas le module TCF. '
            'Passez à la formule Intégral pour 3 mois d\'accès complet à Civique + TCF.',
            style: AppFonts.jakarta(
              size: 14,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _TcfPaywallCopyButton(closeOnTap: true),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Plus tard',
              style: AppFonts.jakarta(
                size: 14,
                color: AppColors.muted,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TcfPaywallCopyButton extends StatelessWidget {
  const _TcfPaywallCopyButton({this.closeOnTap = false});

  /// Si true, ferme le sheet/dialog parent après le clic (cas modal sheet).
  final bool closeOnTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () async {
        await Clipboard.setData(const ClipboardData(text: tcfPaywallUrl));
        if (!context.mounted) return;
        if (closeOnTap) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Lien copié : $tcfPaywallUrl',
              style: AppFonts.jakarta(color: AppColors.white, size: 13),
            ),
          ),
        );
      },
      child: Text(
        'Passer à Intégral',
        style: AppFonts.jakarta(
          size: 15,
          weight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}
