import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/premium_lock.dart';
import '../plan_labels.dart';

/// La carte d'offre du Plan (`CPaywallCard` de la maquette), affichée aux
/// comptes **sans accès TCF**, juste après « Mes priorités ».
///
/// 🛑 **Elle ne masque rien et ne remplace pas la barre « Version gratuite »**
/// du haut d'écran : celle-ci explique en une ligne pourquoi certains
/// entraînements portent un cadenas, celle-ci dit ce que l'abonnement ouvre.
/// La maquette porte bien les deux. Le Plan reste intégralement visible sans
/// abonnement — seuls les **accès** sont fermés, un par un, par le `locked`
/// que le serveur pose.
///
/// Les deux gestes appellent le **même** [showTcfLockPaywall] : l'app n'a
/// qu'une porte d'abonnement, jamais un second chemin d'achat.
class PlanPaywallCard extends StatelessWidget {
  const PlanPaywallCard({
    super.key,
    required this.onSubscribe,
    this.title = kPlanPaywallTitle,
  });

  final VoidCallback onSubscribe;

  /// Le titre se surcharge (la maquette l'adapte au contexte, par exemple à la
  /// fin d'une séance) ; les avantages, eux, ne bougent pas.
  final String title;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: AppColors.blue,
                padding: const EdgeInsets.fromLTRB(18, 17, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.display(
                        size: 19,
                        height: 1.15,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 13),
                    const PremiumBenefitList(benefits: kPlanPaywallBenefits),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      button: true,
                      label: kUnlockPlanCta,
                      child: AppButton(
                        label: kUnlockPlanCta,
                        iconRight: LucideIcons.arrowRight,
                        height: 48,
                        onPressed: onSubscribe,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppButton(
                      label: kPlanPaywallFormulas,
                      variant: AppButtonVariant.ghost,
                      height: 40,
                      onPressed: onSubscribe,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
