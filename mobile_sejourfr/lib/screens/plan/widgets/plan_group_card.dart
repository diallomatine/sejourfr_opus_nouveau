import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_lock.dart';
import '../plan_labels.dart';
import '../plan_milestone_labels.dart';
import 'plan_tokens.dart';

/// **L'encart rétractable d'une épreuve.**
///
/// Fermé, il reste lisible : l'icône du domaine, le nom de l'épreuve, la
/// pastille de sa tâche (ou son repère de contexte) et une ligne de résumé.
/// Ouvert, il déroule ses lignes.
///
/// 🛑 **Un encart verrouillé ne se déplie pas** : son chevron est remplacé par
/// un cadenas et son tap ouvre l'offre. Le verrou est **lu** sur les `locked`
/// servis (un encart n'est verrouillé que si toutes ses lignes le sont) — jamais
/// déduit de sa place dans la liste.
///
/// Extrait dès la première passe parce que la séance et les priorités
/// l'affichent toutes les deux : deux copies auraient fini par ouvrir et fermer
/// différemment.
class PlanGroupCard extends StatelessWidget {
  const PlanGroupCard({
    super.key,
    required this.epreuve,
    required this.task,
    required this.context_,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    required this.children,
    this.dim = false,
    this.locked = false,
    this.trailing,
  });

  /// `null` sur un jalon d'examen complet : la pastille garde alors son icône
  /// générique plutôt que d'emprunter celle d'un domaine deviné.
  final EpreuveType? epreuve;

  /// La tâche du groupe. `null` en compréhension, sur une mesure et sur un
  /// jalon — c'est alors [context_] qui sert de repère.
  final SkillTaskCode? task;

  /// Le repère d'un encart sans tâche (« Niveau B1 », « Jalon »). Nommé avec un
  /// souligné parce que `context` est déjà le paramètre de `build`.
  final String? context_;

  final String summary;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  /// Un encart entièrement fait s'estompe : il reste lisible, il n'attire plus.
  final bool dim;

  final bool locked;

  /// La coche verte d'un encart terminé, posée avant l'affordance.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final open = expanded && !locked;
    final title = epreuve == null
        ? kPlanMilestoneFullTitle
        : planDomainLabel(epreuve!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          // 🛑 **L'état plié/déplié est ANNONCÉ** (`expanded`), comme
          // l'`aria-expanded` du web : sans lui, un lecteur d'écran entend un
          // bouton sans savoir ce qu'il vient d'ouvrir. `null` quand l'encart
          // est verrouillé — il ne se déplie pas, il mène à l'offre.
          //
          // ⚠️ L'action reste portée par ce nœud (`onTap` ci-dessous) et
          // l'`InkWell` cesse d'en créer un second (`excludeFromSemantics`).
          // Ce n'est **pas** `Semantics(excludeSemantics: true)`, qui viderait
          // `visitChildrenForSemantics` et ferait disparaître l'action.
          child: Semantics(
            button: true,
            expanded: locked ? null : open,
            onTap: onToggle,
            child: InkWell(
              onTap: onToggle,
              excludeFromSemantics: true,
              child: Opacity(
                opacity: dim ? 0.7 : 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                  child: Row(
                    children: [
                      PlanDomainTile(epreuve: epreuve, filled: open),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.display(size: 15.5),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                if (task != null)
                                  PlanTaskBadge(task: task!)
                                else if (context_ != null)
                                  PlanContextBadge(label: context_!),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.ui(
                                size: 12.5,
                                height: 1.35,
                                color: AppColors.inkFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (trailing != null) ...[
                        trailing!,
                        const SizedBox(width: 8),
                      ],
                      if (locked)
                        const PremiumLockPill(size: 24)
                      else
                        AnimatedRotation(
                          turns: open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: const Icon(
                            LucideIcons.chevronDown,
                            size: 17,
                            color: AppColors.inkFaint,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
          crossFadeState:
              open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }
}

/// **Une ligne à l'intérieur d'un encart.**
///
/// Le contenu ([label], [sub]) est **le vrai** : verrouillé, il passe derrière
/// un rideau de flou sans changer d'un mot, et c'est l'appelant qui l'enveloppe
/// — ce qui doit rester net ([trailing], la coche, le cadenas) vit **hors** du
/// rideau.
class PlanGroupRow extends StatelessWidget {
  const PlanGroupRow({
    super.key,
    required this.label,
    required this.onTap,
    this.sub,
    this.trailing,
    this.first = false,
    this.done = false,
  });

  /// Déjà enveloppé de son rideau par l'appelant quand la ligne est verrouillée.
  final Widget label;
  final Widget? sub;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool first;
  final bool done;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: first
                ? null
                : const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.lineSoft),
                    ),
                  ),
            child: Opacity(
              opacity: done ? 0.6 : 1,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label,
                        if (sub != null) ...[
                          const SizedBox(height: 2),
                          sub!,
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 11),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

/// La coche verte d'un élément fait — même pastille sur une ligne et sur
/// l'en-tête d'un encart terminé.
class PlanDoneMark extends StatelessWidget {
  const PlanDoneMark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.greenLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          LucideIcons.check,
          size: size * 0.6,
          color: AppColors.green,
        ),
      );
}
