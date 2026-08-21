/// Les blocs de **guidage** d'un petit sujet : ce qu'il faut faire, la
/// situation, et les contraintes visibles d'un coup d'œil.
///
/// L'écran d'un petit sujet ne raconte plus l'exercice, il le fait faire : ces
/// trois blocs remplacent le critère brut, la phrase d'objectif et les encarts
/// pédagogiques, et tiennent au-dessus de la ligne de flottaison pour que la
/// zone de production reste visible sans défiler.
///
/// **Les quatre champs de guidage peuvent être absents** (sujet créé depuis la
/// console d'administration) : chaque bloc se retire ou retombe sur la donnée
/// historique, jamais sur un cadre vide.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';

/// Table **unique et exhaustive** code d'étiquette ↔ icône Lucide.
///
/// [SkillConstraintIcon.unknown] est le repli d'un code non prévu : c'est lui
/// qui garantit qu'une étiquette venue de l'admin s'affiche toujours avec une
/// icône, sans jamais faire échouer le `switch`.
IconData skillConstraintIcon(SkillConstraintIcon icon) => switch (icon) {
      SkillConstraintIcon.tone => LucideIcons.heart,
      SkillConstraintIcon.person => LucideIcons.user,
      SkillConstraintIcon.time => LucideIcons.clock,
      SkillConstraintIcon.place => LucideIcons.mapPin,
      SkillConstraintIcon.number => LucideIcons.hash,
      SkillConstraintIcon.tense => LucideIcons.history,
      SkillConstraintIcon.structure => LucideIcons.listOrdered,
      SkillConstraintIcon.example => LucideIcons.quote,
      SkillConstraintIcon.unknown => LucideIcons.circleDot,
    };

/// Plafonds du contrat gelé, identiques au web (`skill-guidance.ts`). Le
/// contenu publié les respecte déjà ; on les applique quand même, pour qu'une
/// saisie d'administration trop généreuse déborde **en base et non à l'écran**.
const int kMaxChecklistItems = 4;
const int kMaxConstraintTags = 3;

/// Les gestes à accomplir, plafonnés. Vide = pas de check-list : l'appelant
/// retombe sur la consigne du sujet. Le nettoyage (chaînes blanches) est déjà
/// fait au décodage du DTO.
List<String> skillChecklist(SkillPromptDto prompt) =>
    prompt.checklist.take(kMaxChecklistItems).toList(growable: false);

/// Les étiquettes de contrainte, plafonnées. Au-delà de trois, la rangée passe
/// sur une deuxième ligne et pousse la zone de production sous la ligne de
/// flottaison.
List<SkillConstraintTag> skillConstraintTags(SkillPromptDto prompt) =>
    prompt.constraintTags.take(kMaxConstraintTags).toList(growable: false);

/// Une durée en toutes lettres : `45 secondes`, `1 min 30`, `2 minutes`.
///
/// Au-delà de 60 s, « ≈ 90 secondes » se compte de tête ; « ≈ 1 min 30 » se
/// lit. Même règle que le web (`spellDuration`).
String _spellDuration(int seconds) {
  if (seconds < 60) return '$seconds secondes';
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (rest == 0) return minutes == 1 ? '1 minute' : '$minutes minutes';
  return '$minutes min $rest';
}

/// La puce de **longueur**, générée depuis les bornes déjà en base — jamais
/// portée par une étiquette de contrainte, jamais dupliquée.
///
/// `null` quand le sujet n'a aucune borne : on n'invente pas une consigne de
/// longueur. Une **seule** borne suffit en revanche à écrire un repère
/// (« ≈ 15 mots minimum ») : la taire, c'était perdre une consigne réellement
/// posée en base. Indicatif, **jamais bloquant** (règle 15 de la spec).
String? skillLengthHint(SkillPromptDto prompt) {
  if (prompt.section.isEo) {
    final seconds = prompt.recommendedDurationSeconds;
    if (seconds == null || seconds <= 0) return null;
    return '≈ ${_spellDuration(seconds)}';
  }
  final min = prompt.recommendedMinWords;
  final max = prompt.recommendedMaxWords;
  if (min != null && max != null) return '≈ $min–$max mots';
  if (min != null) return '≈ $min mots minimum';
  if (max != null) return '≈ $max mots maximum';
  return null;
}

/// Coque commune des cartes de guidage : pastille d'icône teintée de l'accent,
/// titre, puis le contenu aligné sous le titre.
class SkillGuidanceCard extends StatelessWidget {
  const SkillGuidanceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.ui(size: 14, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          // Le corps prend **toute** la largeur de la carte : la référence
          // l'aligne sous le titre, mais sur un téléphone étroit ce retrait de
          // 40 px coûte une ligne de repli par paragraphe — donc la zone de
          // production sous la ligne de flottaison, ce qu'on corrige ici.
          child,
        ],
      ),
    );
  }
}

/// « Ce qu'il faut faire » — les 2 à 4 gestes à l'impératif, chacun précédé
/// d'une pastille cochée.
///
/// Sans check-list, la carte **retombe sur la consigne** ([fallback]) plutôt
/// que de disparaître : le candidat doit toujours savoir ce qu'on lui demande.
class SkillChecklistCard extends StatelessWidget {
  const SkillChecklistCard({
    super.key,
    required this.checklist,
    required this.fallback,
    required this.accent,
  });

  final List<String> checklist;
  final String fallback;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SkillGuidanceCard(
      icon: LucideIcons.clipboardList,
      title: "Ce qu'il faut faire",
      accent: accent,
      child: checklist.isEmpty
          ? Text(
              fallback,
              style: AppFonts.ui(size: 13, height: 1.45),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < checklist.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          LucideIcons.circleCheck,
                          size: 16,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          checklist[i],
                          style: AppFonts.ui(
                            size: 13,
                            height: 1.4,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

/// « Situation » — le contexte du sujet, resserré.
///
/// **Panneau, pas carte** : fond teinté de l'accent et liseré de 3 px à gauche,
/// comme le mini-sujet de la maquette. Deux raisons, dans cet ordre : c'est le
/// **texte à traiter**, il ne doit pas se lire comme un encart de conseil de
/// plus ; et sans la rangée pastille + titre d'une [SkillGuidanceCard] il coûte
/// une ligne de moins au-dessus de la zone de production.
class SkillSituationCard extends StatelessWidget {
  const SkillSituationCard({
    super.key,
    required this.context,
    required this.accent,
  });

  final String context;
  final Color accent;

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(AppRadii.sm),
          right: Radius.circular(18),
        ),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SITUATION', style: AppFonts.label(size: 10, color: accent)),
          const SizedBox(height: 6),
          Text(
            context,
            style: AppFonts.ui(size: 13.5, height: 1.45, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}

/// La rangée de puces : la **longueur** d'abord, puis les étiquettes de
/// contrainte du sujet, chacune avec son icône.
///
/// Sans étiquette, seule la longueur reste ; sans borne de longueur non plus,
/// la rangée disparaît au lieu d'occuper une ligne vide.
class SkillConstraintRow extends StatelessWidget {
  const SkillConstraintRow({
    super.key,
    required this.lengthHint,
    required this.tags,
    required this.isEo,
  });

  final String? lengthHint;
  final List<SkillConstraintTag> tags;
  final bool isEo;

  bool get isEmpty => lengthHint == null && tags.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (lengthHint != null)
          _ConstraintPill(
            icon: isEo ? LucideIcons.timer : LucideIcons.type,
            label: lengthHint!,
          ),
        for (final tag in tags)
          _ConstraintPill(
            icon: skillConstraintIcon(tag.icon),
            label: tag.label,
          ),
      ],
    );
  }
}

class _ConstraintPill extends StatelessWidget {
  const _ConstraintPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.inkSoft),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppFonts.ui(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
