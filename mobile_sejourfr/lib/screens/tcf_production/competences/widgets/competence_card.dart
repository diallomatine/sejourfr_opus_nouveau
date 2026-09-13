import 'package:flutter/material.dart';

import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../expression_labels.dart';
import '../../widgets/production_common.dart';
import '../../../../core/utils/skill_progress.dart';
import '../../../../core/widgets/premium_lock.dart';
import '../../../../core/widgets/pressable_card.dart';

/// Ligne d'une compétence, structure de la maquette client : **anneau de
/// progression** (« 2/5 »), titre, état en clair, chevron.
///
/// L'anneau a remplacé la pastille de numéro + barre fine : le rang d'une
/// compétence dans sa tâche n'apprend rien au candidat, alors que « où j'en
/// suis sur cette compétence » est exactement ce qu'il vient chercher.
///
/// 🛑 **« Acquis » ⇔ `masteryState == SOLID`, et rien d'autre** (arbitrage du
/// 2026-09-12) : transfert **prouvé sur une production complète**, pas une
/// série de micro-exercices terminée. La ligne d'état dit les deux —
/// « Acquis », « Série terminée · 5/5 », « En cours · 2/5 réussis »,
/// « À découvrir » — parce que les confondre reproduirait le défaut que le
/// dépôt nomme « NON FRAGILE ≠ PLUS RIEN À APPRENDRE ». Tout vient de
/// `expression_labels.dart`, miroir de `web_sejoufr/lib/expression.ts`.
///
/// ⚠️ **Sans palier sur la pastille** : le serveur sait dire « cette compétence
/// est solide », jamais « tu l'as au A2 mais pas au B2 ».
///
/// ⚠️ L'anneau de progression a quitté la carte (maquette `detail_tache.png`) :
/// il répétait en image ce que la ligne d'état dit en mots.
///
/// Une compétence **verrouillée** (`skill.locked`, calculé serveur) reste
/// entièrement lisible : titre et état ne bougent pas, l'anneau cède la place
/// au cadenas et la pilule « Premium » dit ce qui l'ouvrirait. Où mène le tap,
/// c'est l'appelant qui en décide — cette carte ne fait qu'annoncer le verrou.
class CompetenceCard extends StatelessWidget {
  const CompetenceCard({
    super.key,
    required this.skill,
    required this.accent,
    required this.onTap,
  });

  final SkillDto skill;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = competenceBadge(skill);

    return PressableCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Verrouillée, la compétence garde tout : seul le cadenas s'ajoute.
            if (skill.locked) ...[
              const PremiumLockTile(size: 46),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.title,
                    style: AppFonts.ui(
                      size: 14.5,
                      weight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // L'état **reste** sur une compétence verrouillée : un
                  // candidat qui y a déjà produit garde ce qu'il a appris de
                  // ses propres productions, le cadenas ne l'efface pas.
                  Text(
                    competenceStatus(skill),
                    style: AppFonts.ui(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (skill.locked)
              const PremiumLockTag()
            else
              ExpressionStateBadge(label: badge.label),
          ],
        ),
      ),
    );
  }
}

/// État d'une compétence en une phrase, depuis les **compteurs servis par
/// `GET /api/skills`** — aucun agrégat inventé.
///
/// La règle vit dans `core/utils/skill_progress.dart` depuis que le Plan la
/// lit aussi, sur les compteurs de `GET /api/me/plan` : ici on ne fait que
/// l'appliquer à un [SkillDto].
String competenceProgressLabel(SkillDto skill) => skillProgressLabel(
      promptCount: skill.promptCount,
      attemptedCount: skill.attemptedCount,
      validatedCount: skill.validatedCount,
    );
