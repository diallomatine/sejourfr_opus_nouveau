import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/preparation_labels.dart';
import '../theme/app_theme.dart';
import 'sejour/sejour_kit.dart';

/// **Affiner votre Plan** — l'invitation au diagnostic complet.
///
/// 🛑 **Le diagnostic complet ne bloque jamais le Plan** (arbitrage du
/// propriétaire, 2026-09-12). Il l'affine — d'où sa place, jamais avant le
/// contenu du Plan.
///
/// 🛑 **C'est désormais le SEUL appel à compléter son profil** (2026-09-13) :
/// la section « Compléter mon profil » et ses cartes d'épreuve ont été
/// supprimées, et cette carte a pris leur emplacement. D'où le bouton **plein**
/// `blue` (Bleu France) : un contour ne se voyait plus une fois seul en piste.
/// 🛑 **Jamais `primary`** pour autant — le rouge reste réservé au CTA critique
/// de la page, « Débloquer mon plan » en barre basse d'un compte gratuit.
///
/// 🛑 **Un seul widget, un lecteur** — l'Accueil. Le Plan a perdu sa carte le
/// 2026-09-19 (arbitrage du propriétaire) : ne pas l'y remettre.
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
          // 🛑 `blue` (plein), jamais `primary` : sur un Plan gratuit, le seul
          // bouton ROUGE de la page reste « Débloquer mon plan ».
          SfButton(
            label: info.cta,
            variant: SfButtonVariant.blue,
            onPressed: () => context.push(info.route),
          ),
        ],
      ),
    );

    return pad ? Padding(padding: sfGutter, child: carte) : carte;
  }
}
