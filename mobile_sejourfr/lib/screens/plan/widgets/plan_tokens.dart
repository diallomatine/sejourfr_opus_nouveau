import 'package:flutter/material.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_progress.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/progress_ring.dart';
import '../plan_labels.dart';

/// Les **primitives du Plan** : la pastille d'un domaine, la pilule de sa
/// priorité, le rail des paliers et les points d'une étape.
///
/// ⚠️ **Aucune teinte nouvelle.** Tout se peint avec `AppColors` / `TagTone`
/// existants : un même état ne doit pas changer de couleur d'un écran à
/// l'autre. Les deux épreuves d'expression sont **bleues** comme le reste du
/// TCF (décision client) — le rouge reste réservé à l'urgence.

/// La pastille carrée d'un domaine : son icône, sur fond bleu clair. [filled]
/// la remplit — réservé au domaine que le Plan traite en priorité forte, pour
/// qu'un seul élément de la liste attire l'œil.
class PlanDomainTile extends StatelessWidget {
  const PlanDomainTile({
    super.key,
    required this.epreuve,
    this.size = 38,
    this.filled = false,
  });

  /// `null` sur une ligne qui ne porte pas de domaine (un jalon complet, par
  /// exemple) : la pastille garde alors son icône générique plutôt que
  /// d'emprunter celle d'un domaine qu'on aurait deviné.
  final EpreuveType? epreuve;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.blue : AppColors.blueLight,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Icon(
          planDomainIcon(epreuve),
          size: size * 0.52,
          color: filled ? AppColors.white : AppColors.blueDark,
        ),
      );
}

/// Ton de pilule d'une priorité de domaine. **Dérivé, jamais une table de
/// couleurs de plus** : « priorité forte » se peint comme le statut
/// `PRIORITY` d'une compétence (rouge), « à travailler » comme un état bleu,
/// le reste reste neutre — un domaine qu'on n'a pas encore mesuré n'est pas un
/// domaine faible.
extension PlanDomainPriorityTone on PlanDomainPriority {
  TagTone get tone => switch (this) {
        PlanDomainPriority.forte => TagTone.red,
        PlanDomainPriority.aTravailler => TagTone.blue,
        PlanDomainPriority.entretien => TagTone.neutral,
        PlanDomainPriority.pasEncorePrioritaire => TagTone.neutral,
        PlanDomainPriority.aEvaluer => TagTone.ghost,
      };
}

/// La pilule de priorité d'un domaine. Le libellé est **gelé côté serveur**
/// (`PlanDomainPriority.getLabel()`), recopié dans l'enum : jamais une chaîne
/// écrite ici.
class PlanDomainPriorityTag extends StatelessWidget {
  const PlanDomainPriorityTag({
    super.key,
    required this.priority,
    this.compact = true,
  });

  final PlanDomainPriority priority;
  final bool compact;

  @override
  Widget build(BuildContext context) => AppTag(
        label: priority.label,
        tone: priority.tone,
        compact: compact,
      );
}

/// Le rail des paliers `A2 → B1 → B2`, avec le palier courant en évidence.
///
/// [current] est **nullable** : tant que rien n'est mesuré, aucun point n'est
/// allumé — on ne place pas le candidat sur une échelle par défaut.
/// [onDark] est la variante posée sur le dégradé de la carte de priorité.
class PlanLevelRail extends StatelessWidget {
  const PlanLevelRail({super.key, required this.current, this.onDark = false});

  final TargetLevel? current;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    const levels = TargetLevel.values;
    final index = current == null ? -1 : levels.indexOf(current!);
    final reached = onDark
        ? AppColors.white.withValues(alpha: 0.95)
        : AppColors.blue;
    final empty = onDark
        ? AppColors.white.withValues(alpha: 0.28)
        : AppColors.surface3;
    final textOn = onDark ? AppColors.white : AppColors.ink;
    final textOff = onDark
        ? AppColors.white.withValues(alpha: 0.62)
        : AppColors.inkFaint;

    return Row(
      children: [
        for (var i = 0; i < levels.length; i++) ...[
          _RailDot(
            label: levels[i].wire,
            reached: i <= index,
            active: i == index,
            reachedColor: reached,
            emptyColor: empty,
            textColor: i <= index ? textOn : textOff,
            onDark: onDark,
          ),
          if (i < levels.length - 1)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: i < index ? reached : empty,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _RailDot extends StatelessWidget {
  const _RailDot({
    required this.label,
    required this.reached,
    required this.active,
    required this.reachedColor,
    required this.emptyColor,
    required this.textColor,
    required this.onDark,
  });

  final String label;
  final bool reached;
  final bool active;
  final Color reachedColor;
  final Color emptyColor;
  final Color textColor;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final size = active ? 11.0 : 8.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: reached ? reachedColor : emptyColor,
            shape: BoxShape.circle,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: onDark
                          ? AppColors.white.withValues(alpha: 0.22)
                          : AppColors.blueLight,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: AppFonts.ui(
            size: 12.5,
            weight: active ? FontWeight.w800 : FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

/// Les points d'une étape : un par sujet du périmètre servi, remplis pour ceux
/// qui ont été **traités**. Le total vient du serveur — une compétence qui
/// publie moins de sujets a une étape plus courte.
class PlanStepDots extends StatelessWidget {
  const PlanStepDots({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    final filled = done.clamp(0, total);
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i < filled ? AppColors.blue : AppColors.surface3,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// La note discrète de bas de bloc : une nuance, jamais une alerte.
class PlanNote extends StatelessWidget {
  const PlanNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          text,
          style: AppFonts.ui(size: 12, height: 1.5, color: AppColors.inkFaint),
        ),
      );
}

/// Le numéro d'un rang dans une liste ordonnée (priorités, chemin, étapes).
class PlanRankBadge extends StatelessWidget {
  const PlanRankBadge({
    super.key,
    required this.rank,
    this.tone = AppColors.inkFaint,
    this.icon,
    this.semanticsLabel,
    this.size = 24,
  });

  final int rank;
  final Color tone;
  final IconData? icon;
  final String? semanticsLabel;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: icon != null
            ? Icon(
                icon,
                size: size * 0.55,
                color: tone,
                semanticLabel: semanticsLabel,
              )
            : Text(
                '$rank',
                style: AppFonts.display(size: size * 0.5, color: tone),
              ),
      );
}

/// L'anneau d'une compétence : sujets **traités** sur sujets publiés, tels que
/// le serveur les compte.
///
/// ⚠️ Sur une **étape**, ce sont les compteurs d'étape (5 sujets) qu'on lui
/// passe, jamais ceux de la compétence entière (15) — les deux jeux existent
/// côte à côte sur le DTO exprès.
class PlanSkillRing extends StatelessWidget {
  const PlanSkillRing({
    super.key,
    required this.promptCount,
    required this.attemptedCount,
    required this.color,
    this.size = 46,
  });

  final int promptCount;
  final int attemptedCount;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final attempted = attemptedCount.clamp(0, promptCount);
    return ProgressRing(
      value: skillProgressValue(
            promptCount: promptCount,
            attemptedCount: attemptedCount,
          ) *
          100,
      size: size,
      stroke: 5,
      color: color,
      label: promptCount == 0 ? '—' : '$attempted',
      sub: promptCount == 0 ? null : '/$promptCount',
      textColor: color,
      subColor: AppColors.inkFaint,
    );
  }
}
