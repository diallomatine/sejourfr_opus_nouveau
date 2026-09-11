import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/preparation_labels.dart';
import '../theme/app_theme.dart';
import 'sejour/sejour_kit.dart';

/// **Affiner votre Plan** — l'invitation au diagnostic complet, en action
/// **secondaire**.
///
/// 🛑 **Le diagnostic complet ne bloque jamais le Plan** (arbitrage du
/// propriétaire, 2026-09-12). Il l'affine. Cette carte se pose donc **après**
/// le contenu principal, et ne concurrence jamais le CTA d'abonnement d'un
/// compte gratuit : bouton `line` (contour), jamais `primary`.
///
/// 🛑 **Un seul widget, trois lecteurs** — Plan gratuit, Plan abonné, Accueil.
/// Ses phrases vivent dans une **autorité unique**, `affinerPlan()`
/// (`core/models/preparation_labels.dart`), miroir de
/// `web_sejoufr/lib/preparation.ts`. Trois copies auraient fini par inviter à
/// trois choses différentes.
///
/// 🛑 **Rien n'est compté ici.** `fait`, `total` et la prochaine épreuve sont
/// **servis** ; à `4 / 4` l'autorité rend `null` et la carte n'existe pas.
///
/// Miroir de `web_sejoufr/app/_components/plan/AffinerPlanCard.tsx`.
class AffinerPlanCard extends StatelessWidget {
  const AffinerPlanCard({super.key, required this.info, this.pad = true});

  final AffinerPlan info;

  /// `false` quand l'hôte pose déjà sa propre gouttière (l'Accueil, dont la
  /// liste a son `padding`).
  final bool pad;

  @override
  Widget build(BuildContext context) {
    // Le ratio est **servi**, jamais un pourcentage reconstruit : il vaut
    // exactement « épreuves terminées sur épreuves du diagnostic ».
    final ratio = info.total > 0 ? info.fait / info.total : 0.0;

    final carte = SfCard(
      variant: SfCardVariant.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            info.titre,
            style: AppFonts.display(size: 16, weight: FontWeight.w700, height: 1.25),
          ),
          if (info.progression != null) ...[
            const SizedBox(height: 6),
            SfLabel(info.progression!, color: AppColors.blue),
          ],
          if (info.enCours)
            SfProgressMini(ratio: ratio, semanticsLabel: info.progression),
          const SizedBox(height: 10),
          SfInsight(info.texte),
          if (info.prochaineEpreuve != null) ...[
            const SizedBox(height: 6),
            SfTiny(info.prochaineEpreuve!),
          ],
          const SizedBox(height: 12),
          // 🛑 `line`, jamais `primary` : sur un Plan gratuit, le seul bouton
          // plein de la page reste « Débloquer mon plan ».
          SfButton(
            label: info.cta,
            variant: SfButtonVariant.line,
            onPressed: () => context.push(info.route),
          ),
        ],
      ),
    );

    return pad ? Padding(padding: sfGutter, child: carte) : carte;
  }
}
