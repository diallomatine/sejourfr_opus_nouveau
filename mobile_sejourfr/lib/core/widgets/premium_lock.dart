import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../analytics/analytics.dart';
import '../models/billing_models.dart';
import '../theme/app_theme.dart';
import 'app_tag.dart';
import 'paywall_context.dart';
import 'paywall_sheet.dart';

/// Le verrou freemium d'un contenu TCF, **rendu partout de la même façon** :
/// module Compétences (une compétence, un petit sujet) et Plan (une étape, une
/// compétence observée, l'exercice recommandé).
///
/// ⚠ Aucune règle n'est décidée ici. Le serveur calcule quelle compétence est
/// ouverte et combien de ses sujets le sont, et le publie en un booléen
/// `locked` sur chaque DTO ; l'app le **reflète**. Ne jamais réintroduire un
/// « si l'index dépasse N alors cadenas » côté client : c'est exactement ce que
/// la règle du dépôt interdit, et le 403 serveur reste l'arbitre final.

/// Badge d'un contenu verrouillé — **une seule formulation dans tout le
/// module**, cadenas compris. Miroir mot pour mot de `SkillLockBadge` côté web
/// (`app/_components/skill-ui/SkillLayout.tsx`).
const String kPremiumLockTagLabel = 'Premium';

/// L'appel à l'action d'une zone de production verrouillée. Miroir du
/// `ctaLabel` par défaut de `SkillLockedCard` côté web. Wording neutre exigé
/// par les guidelines Apple 3.1.1 : ni prix, ni verbe d'achat.
const String kPremiumLockCta = 'Voir l\'abonnement Intégral';

/// Ouvre le parcours d'abonnement — **le seul**, celui de `showPaywallSheet`.
/// Le contenu verrouillé est toujours du TCF, donc l'offre Intégral.
///
/// [ref] + [ctaLocation] ne se passent que sur un **vrai clic** du candidat
/// (cf. `showPaywallSheet`) : une ouverture subie ne compte pas.
Future<void> showTcfLockPaywall(
  BuildContext context, {
  WidgetRef? ref,
  AnalyticsCtaLocation? ctaLocation,
  PaywallOrigin origin = PaywallOrigin.ailleurs,
}) =>
    showPaywallSheet(
      context,
      initialTarget: PlanModuleTarget.integral,
      ref: ref,
      ctaLocation: ctaLocation,
      origin: origin,
    );

/// Pilule « Abonnement » à poser à côté d'un titre ou d'un statut.
class PremiumLockTag extends StatelessWidget {
  const PremiumLockTag({super.key});

  @override
  Widget build(BuildContext context) => const AppTag(
        label: kPremiumLockTagLabel,
        tone: TagTone.neutral,
        icon: LucideIcons.lock,
        compact: true,
      );
}

/// Le cadenas d'une **ligne** verrouillée : il prend la place du chevron ou de
/// la coche, à la taille d'une affordance de fin de ligne. On l'emploie quand
/// le contenu de la ligne est **flouté** (`BlurredContent`) — la pilule
/// `PremiumLockTag` y ajouterait un mot lisible à côté d'un texte qui ne l'est
/// pas, et surchargerait la ligne.
///
/// Il porte la sémantique que le flou retire : le lecteur d'écran entend
/// « Premium », donc le verrou reste annoncé même quand rien n'est lisible.
class PremiumLockPill extends StatelessWidget {
  const PremiumLockPill({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: kPremiumLockTagLabel,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.surface3,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.lock,
            size: size * 0.54,
            color: AppColors.inkFaint,
          ),
        ),
      );
}

/// La pastille de tête d'une carte verrouillée : elle remplace l'anneau de
/// progression ou le numéro de sujet, **à la même taille**, parce qu'un anneau
/// à zéro n'aurait rien à raconter. Même geste que `SkillCard` / `PromptCard`
/// côté web.
class PremiumLockTile extends StatelessWidget {
  const PremiumLockTile({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          LucideIcons.lock,
          size: size * 0.42,
          color: AppColors.inkFaint,
        ),
      );
}

/// L'appel à l'action d'une carte d'offre — **jamais un second chemin
/// d'achat** : il déclenche [showTcfLockPaywall], comme le Plan, le diagnostic
/// et le module Compétences. Wording neutre (guidelines Apple 3.1.1) : ni
/// prix, ni verbe d'achat.
///
/// Il vit ici plutôt que dans l'un des deux écrans qui l'affichent : il était
/// déclaré par le rapport de diagnostic, et la carte du Plan l'aurait recopié.
/// Miroir mot pour mot du web (`Débloquer mon plan`).
const String kUnlockPlanCta = 'Débloquer mon plan';

/// La liste « ce que l'abonnement ouvre », cochée ligne à ligne.
///
/// Extraite à la **2ᵉ occurrence** : le rapport de diagnostic et la carte
/// d'offre du Plan présentent la même chose — des phrases courtes précédées
/// d'une coche, sur un aplat coloré — avec des **textes différents** (le
/// rapport décrit ce qu'il vient de laisser entrevoir, le Plan décrit le plan
/// complet). C'est la mise en forme qui est partagée, pas le contenu.
class PremiumBenefitList extends StatelessWidget {
  const PremiumBenefitList({
    super.key,
    required this.benefits,
    this.checkColor = AppColors.white,
    this.textColor = AppColors.white,
  });

  final List<String> benefits;
  final Color checkColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.check,
                      size: 14,
                      color: checkColor,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      benefit,
                      style: AppFonts.ui(
                        size: 12.5,
                        height: 1.4,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}
