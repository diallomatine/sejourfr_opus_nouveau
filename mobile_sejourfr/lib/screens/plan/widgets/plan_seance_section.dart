import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/blurred_content.dart';
import '../../../core/widgets/premium_lock.dart';
import '../plan_actions.dart';
import '../plan_groups.dart';
import '../plan_labels.dart';
import 'plan_group_card.dart';

/// **La séance du jour, groupée par épreuve et par tâche.**
///
/// On ne lit plus une liste plate d'entraînements mais « où je travaille →
/// quelle compétence → quoi faire » : un encart rétractable par épreuve (et par
/// tâche en expression), qui reste lisible fermé.
///
/// C'est une **vue** du Plan : chaque ligne reprend un exercice déjà désigné
/// par le serveur, dans l'ordre d'exécution qu'il a décidé. On ne filtre pas,
/// on ne retrie pas, et **aucune date n'intervient** — « aujourd'hui » est une
/// présentation.
///
/// 🛑 **Rien n'est fabriqué** pour un compte gratuit : une ligne verrouillée
/// affiche son **vrai** titre, simplement passé derrière un rideau de flou
/// (`BlurredContent`), cadenas en fin de ligne et tap qui mène à l'offre. Sa
/// nature et sa durée, elles, restent nettes : elles situent la ligne sans rien
/// livrer. Un encart dont **toutes** les lignes sont verrouillées porte un
/// cadenas à la place du chevron et ne se déplie pas.
///
/// ⚠ Le verrou est **lu** (`planSeanceItemLocked`), jamais déduit du rang de la
/// ligne — et la **coche** l'est aussi (`planSeanceItemDone` : étape bouclée,
/// ou dernière activité datée d'aujourd'hui à Paris). Le marqueur local d'avant
/// disparaissait au redémarrage et ne traversait pas l'appareil.
class PlanSeanceSection extends ConsumerStatefulWidget {
  const PlanSeanceSection({
    super.key,
    required this.plan,
    required this.onWhy,
  });

  final LearningPlan plan;

  final VoidCallback onWhy;

  @override
  ConsumerState<PlanSeanceSection> createState() => _PlanSeanceSectionState();
}

class _PlanSeanceSectionState extends ConsumerState<PlanSeanceSection> {
  /// `null` tant que le candidat n'a rien ouvert ni fermé : l'encart par défaut
  /// est alors le premier qui reste à faire.
  String? _openKey;
  bool _touched = false;

  /// Le premier encart ouvert : celui qui porte la prochaine ligne réellement
  /// faisable, sinon le premier ouvrable, sinon le premier. Miroir du web
  /// (`firstOpenKey`).
  String? _defaultKey(List<PlanSeanceGroup> groups) {
    for (final group in groups) {
      if (group.rows.any((row) => !row.done && !row.locked)) return group.key;
    }
    for (final group in groups) {
      if (!group.locked) return group.key;
    }
    return groups.isEmpty ? null : groups.first.key;
  }

  String? _effectiveKey(List<PlanSeanceGroup> groups) {
    if (!_touched) return _defaultKey(groups);
    final key = _openKey;
    if (key == null) return null;
    return groups.any((group) => group.key == key) ? key : _defaultKey(groups);
  }

  @override
  Widget build(BuildContext context) {
    final seance = widget.plan.seance;
    final items = seance.items;
    final groups = planSeanceGroups(seance);
    // Les deux compteurs se lisent sur les **mêmes** lignes que les encarts :
    // un total calculé à côté finirait par contredire ce qui est affiché.
    final rows = groups.expand((group) => group.rows).toList(growable: false);
    final doneCount = rows.where((row) => row.done).length;
    final freeCount = rows.where((row) => !row.locked).length;
    final openKey = _effectiveKey(groups);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kPlanSeanceTitle, style: AppFonts.display(size: 17)),
                      const SizedBox(height: 3),
                      Text(
                        items.isEmpty
                            ? kPlanSeanceNothingToDo
                            // 🛑 L'en-tête se décide sur les `locked` **servis**,
                            // jamais sur l'accès du compte : c'est le serveur
                            // qui ouvre, et lui seul sait ce qu'il a ouvert.
                            // Miroir du web (`openRows < items.length`).
                            : freeCount == items.length
                                ? planSeanceHeaderMeta(
                                    // Des **épreuves**, pas des encarts : deux
                                    // tâches d'une même épreuve font deux
                                    // encarts et une seule épreuve.
                                    epreuves: groups
                                        .map((group) => group.epreuve)
                                        .toSet()
                                        .length,
                                    items: items.length,
                                    minutes: seance.estimatedMinutes,
                                  )
                                : planSeanceFreeHeaderMeta(
                                    free: freeCount,
                                    items: items.length,
                                    minutes: seance.estimatedMinutes,
                                  ),
                        style: AppFonts.ui(
                          size: 12.5,
                          height: 1.35,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(
                    '$doneCount/${items.length}',
                    style: AppFonts.ui(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: doneCount == items.length
                          ? AppColors.blue
                          : AppColors.inkFaint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                kPlanSeanceEmpty,
                style: AppFonts.ui(
                  size: 13.5,
                  height: 1.5,
                  color: AppColors.inkSoft,
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 3,
              child: ColoredBox(
                color: AppColors.surface3,
                child: _SeanceProgressLine(value: doneCount / items.length),
              ),
            ),
            for (final group in groups)
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.lineSoft)),
                ),
                child: PlanGroupCard(
                  epreuve: group.epreuve,
                  task: group.task,
                  context_: group.context,
                  summary: planSeanceGroupSummary(
                    taskTitle: group.task?.title,
                    count: group.rows.length,
                    minutes: group.minutes,
                  ),
                  expanded: openKey == group.key,
                  dim: group.done,
                  locked: group.locked,
                  trailing: group.done ? const PlanDoneMark() : null,
                  onToggle: () => _toggle(group, openKey),
                  children: [
                    for (var i = 0; i < group.rows.length; i++)
                      _SeanceRow(row: group.rows[i], first: i == 0),
                  ],
                ),
              ),
            _SeanceWhyRow(onTap: widget.onWhy),
          ],
        ],
      ),
    );
  }

  /// [current] est l'encart réellement ouvert au moment du geste — il peut être
  /// celui **par défaut**, que personne n'a encore touché. Le relire ici est ce
  /// qui permet de refermer du premier coup l'encart qu'on voit ouvert.
  void _toggle(PlanSeanceGroup group, String? current) {
    if (group.locked) {
      unawaited(showTcfLockPaywall(
        context,
        ref: ref,
        ctaLocation: AnalyticsCtaLocation.lockedPlan,
      ));
      return;
    }
    setState(() {
      _touched = true;
      _openKey = current == group.key ? null : group.key;
    });
  }
}

/// Le filet de progression **de la séance affichée**, collé sous son en-tête.
/// Un `ProgressTrack` arrondi n'a pas de sens sur 3 px pleine largeur : ici
/// c'est une ligne, pas une jauge de carte.
class _SeanceProgressLine extends StatelessWidget {
  const _SeanceProgressLine({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          heightFactor: 1,
          child: Container(color: AppColors.blue),
        ),
      );
}

class _SeanceRow extends ConsumerWidget {
  const _SeanceRow({required this.row, required this.first});

  final PlanSeanceGroupRow row;
  final bool first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = row.item;
    // Le **vrai** titre. Verrouillé, il passe derrière le rideau sans changer
    // d'un mot : on ne fabrique jamais de fausse ligne.
    final Widget title = Text(
      planItemTitle(item),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppFonts.ui(
        size: 14.5,
        weight: FontWeight.w600,
        height: 1.3,
      ).copyWith(
        decoration: row.done ? TextDecoration.lineThrough : null,
        decorationColor: AppColors.inkFaint,
      ),
    );

    return PlanGroupRow(
      first: first,
      done: row.done,
      onTap: () => openPlanSeanceItem(context, ref, item),
      label: row.locked ? BlurredContent(child: title) : title,
      // 🛑 **La nature et la durée restent NETTES**, même verrouillées : elles
      // disent de quelle sorte d'action il s'agit et combien elle prend, jamais
      // ce qu'il y a à y faire.
      sub: Text(
        planSeanceRowSub(item, row.minutes),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
      ),
      trailing: row.locked
          ? const PremiumLockPill(size: 22)
          : row.done
              ? const PlanDoneMark()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      kPlanSeanceRowStart,
                      style: AppFonts.ui(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: AppColors.blue,
                    ),
                  ],
                ),
    );
  }
}

class _SeanceWhyRow extends StatelessWidget {
  const _SeanceWhyRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface2,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.lineSoft)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kPlanSeanceWhy,
                    style: AppFonts.ui(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 15,
                  color: AppColors.inkFaint,
                ),
              ],
            ),
          ),
        ),
      );
}
