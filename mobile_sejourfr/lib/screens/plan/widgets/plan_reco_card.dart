import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';

/// **La carte « ce que votre plan recommande »**, partagée par les écrans qui
/// l'affichent : Réviser (la reprise du parcours) et chaque écran d'épreuve
/// (l'étape du cycle pour CETTE épreuve).
///
/// ⚠️ Extraite à sa **deuxième** surface (2026-09-20). Elle vivait en privé
/// dans `ReviserScreen` ; la recopier dans les écrans d'épreuve aurait donné
/// deux cartes qui disent la même chose et divergent à la première retouche.
///
/// 🛑 **Elle ne décide rien** : ni le titre, ni le libellé du bouton, ni le
/// geste. Tout lui arrive de l'autorité du Plan (`planNowCard`,
/// `planEpreuveCarte`, `civicNowCard`). Elle pose des mots servis sur la carte
/// du kit.
///
/// Miroir web : `app/_components/plan/PlanRecoCard.tsx`.
class PlanRecoCard extends StatelessWidget {
  const PlanRecoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.variant,
    required this.onContinue,
    this.pad = true,
    required this.label,
    required this.cta,
  });

  final String title;
  final String? subtitle;

  /// Le sur-titre : la reprise, ou le point de départ.
  final String label;

  /// Le bouton. Il dit ce qui va se passer — jamais « Continuer » sur une porte.
  final String cta;

  /// Le pictogramme de ce qu'on reprend — le domaine côté TCF, le thème côté
  /// civique. Servi par l'appelant, qui seul sait de quoi il parle.
  final IconData icon;

  /// Rouge côté TCF, bleu côté civique — la sémantique de parcours du produit.
  final SfButtonVariant variant;
  final VoidCallback onContinue;

  /// 🛑 **La gouttière de l'écran, quand il n'en a pas déjà une.** Réviser rend
  /// ses blocs à plat et compte dessus ; une liste qui porte **son** padding la
  /// doublerait, et la carte serait plus étroite que ce qui la suit.
  final bool pad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: pad
          ? const EdgeInsets.fromLTRB(16, 16, 16, 0)
          : EdgeInsets.zero,
      child: SfCard(
        variant: SfCardVariant.hero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SfLabel(label),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(icon, size: 24, color: AppColors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.display(
                          size: 18,
                          weight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppFonts.ui(
                            size: 13,
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SfButton(
              label: cta,
              variant: variant,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
