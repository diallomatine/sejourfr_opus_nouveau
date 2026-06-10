import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/billing_models.dart';
import '../theme/app_theme.dart';
import 'paywall_sheet.dart';

/// Helper d'ouverture du paywall depuis cette carte. Depuis le lot 4d le
/// paiement se fait via IAP natif (Apple/Google), pas par redirect web —
/// obligation des stores quand on vend du contenu digital.
void _openPaywall(BuildContext context) {
  showPaywallSheet(context, initialTarget: PlanModuleTarget.integral);
}

/// Carte affichée à la place du contenu TCF quand l'utilisateur n'a pas
/// l'accès complet (formule Civique seule ou pas de plan actif).
///
/// Wording volontairement neutre : pas de prix, pas de verbe « payer » /
/// « acheter ». L'app décrit simplement la disponibilité du contenu et
/// ouvre le paywall IAP natif (lot 4d) — aucune mention du site web pour
/// l'achat (Guidelines Apple 3.1.1, pas de steering hors IAP).
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
                child: const Icon(LucideIcons.lock, color: AppColors.blue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Module TCF non activé',
                  style: AppFonts.display(
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
            'Le module TCF (compréhension écrite, compréhension orale et structure '
            'de la langue) n\'est pas inclus dans votre formule actuelle.',
            style: AppFonts.ui(
              size: 14,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous pouvez activer l\'accès complet (Civique + TCF) directement depuis l\'application.',
            style: AppFonts.ui(
              size: 14,
              color: AppColors.ink2,
              weight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _OpenSubscriptionButton(),
        ],
      ),
    );
  }
}

/// Bottom sheet qui présente l'information « module TCF non activé ».
/// Utilisé depuis le ModuleSwitch quand l'utilisateur tente de basculer
/// sur TCF.
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
                child: const Icon(LucideIcons.lock, color: AppColors.blue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Module TCF non activé',
                  style: AppFonts.display(
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
            'Le module TCF n\'est pas inclus dans votre formule actuelle. '
            'Vous pouvez activer l\'accès complet directement depuis l\'application.',
            style: AppFonts.ui(
              size: 14,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _OpenSubscriptionButton(closeOnTap: true),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Plus tard',
              style: AppFonts.ui(
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

class _OpenSubscriptionButton extends StatelessWidget {
  const _OpenSubscriptionButton({this.closeOnTap = false});

  /// Si true, ferme le sheet/dialog parent au clic (cas modal sheet).
  final bool closeOnTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () {
        if (closeOnTap) Navigator.of(context).pop();
        _openPaywall(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Voir les offres',
            style: AppFonts.ui(
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.arrowRight, size: 16),
        ],
      ),
    );
  }
}
