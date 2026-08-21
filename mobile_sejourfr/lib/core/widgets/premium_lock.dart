import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/billing_models.dart';
import '../theme/app_theme.dart';
import 'app_tag.dart';
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
Future<void> showTcfLockPaywall(BuildContext context) =>
    showPaywallSheet(context, initialTarget: PlanModuleTarget.integral);

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
