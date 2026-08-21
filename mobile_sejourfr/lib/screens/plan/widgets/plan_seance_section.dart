import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/blurred_content.dart';
import '../../../core/widgets/premium_lock.dart';
import '../plan_actions.dart';
import '../plan_labels.dart';
import '../plan_milestone_launcher.dart';
import '../plan_milestone_labels.dart';
import '../plan_seance_state.dart';
import 'plan_tokens.dart';

/// **La séance du jour.** Ce que le candidat fait maintenant, et rien de plus.
///
/// C'est une **vue** du Plan : chaque ligne reprend un exercice déjà désigné
/// par le serveur, dans l'ordre d'exécution qu'il a décidé. On ne filtre pas,
/// on ne retrie pas, et **aucune date n'intervient** — « aujourd'hui » est une
/// présentation.
///
/// 🛑 **Rien n'est fabriqué** pour un compte gratuit : une ligne verrouillée
/// affiche son **vrai** contenu, simplement passé derrière un rideau de flou
/// (`BlurredContent`), cadenas en fin de ligne et tap qui mène à l'offre. Son
/// icône de domaine, elle, reste nette : elle situe la ligne sans rien livrer.
///
/// ⚠ Le verrou est **lu** (`planSeanceItemLocked`), jamais déduit du rang de la
/// ligne.
class PlanSeanceSection extends ConsumerWidget {
  const PlanSeanceSection({
    super.key,
    required this.plan,
    required this.onWhy,
  });

  final LearningPlan plan;
  final VoidCallback onWhy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seance = plan.seance;
    final done = ref.watch(planSeanceDoneProvider);
    final items = seance.items;
    final doneCount =
        items.where((i) => done.contains(planSeanceItemKey(i))).length;

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
                            ? 'Aucun entraînement à faire pour l\'instant'
                            : planSeanceMeta(seance),
                        style: AppFonts.ui(
                          size: 12.5,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty)
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
            for (final item in items)
              _SeanceRow(
                item: item,
                done: done.contains(planSeanceItemKey(item)),
              ),
            _SeanceWhyRow(onTap: onWhy),
          ],
        ],
      ),
    );
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
  const _SeanceRow({required this.item, required this.done});

  final PlanSeanceItem item;
  final bool done;

  bool get _locked => planSeanceItemLocked(item);

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (_locked) {
      await showTcfLockPaywall(context);
      return;
    }
    final exercise = item.exercise;
    final milestone = item.milestone;
    if (exercise != null) {
      await openPlanExercise(
        context,
        ref,
        exercise,
        masteryBefore: item.masteryState,
      );
    } else if (milestone != null) {
      await startPlanMilestone(context, ref, milestone);
    } else {
      return;
    }
    // Marqueur local et éphémère : il coche la ligne qu'on vient d'ouvrir. Il
    // ne décide de rien — ni du contenu de la séance, ni d'un verrou, ni d'un
    // compteur d'étape, qui restent servis.
    ref.read(planSeanceDoneProvider.notifier).update(
          (current) => <String>{...current, planSeanceItemKey(item)},
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestone = item.milestone;
    final minutes =
        item.exercise?.estimatedMinutes ?? milestone?.estimatedMinutes ?? 0;
    final title = item.title ?? milestone?.displayTitle ?? 'Entraînement';
    final epreuve = milestone?.epreuve ??
        (item.section == null ? null : planEpreuveOfSection(item.section!));

    // Le contenu **réel** de la ligne. Verrouillé, il passe derrière le rideau
    // sans changer d'un mot : on ne fabrique jamais de fausse ligne.
    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          planItemEyebrow(item),
          style: AppFonts.label(size: 11.5, color: AppColors.inkFaint),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.ui(
            size: 14.5,
            weight: FontWeight.w600,
            height: 1.25,
          ).copyWith(
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.inkFaint,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          minutes > 0
              ? '${planItemKindLabel(item)} · $minutes min'
              : planItemKindLabel(item),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.ui(size: 12.5, color: AppColors.inkFaint),
        ),
      ],
    );

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: () => _open(context, ref),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.lineSoft)),
          ),
          child: Opacity(
            opacity: done ? 0.62 : 1,
            child: Row(
              children: [
                // L'icône de domaine reste **nette** : elle dit de quelle
                // épreuve relève la ligne, pas ce qu'on y ferait.
                PlanDomainTile(epreuve: epreuve, filled: !done),
                const SizedBox(width: 12),
                Expanded(child: _locked ? BlurredContent(child: body) : body),
                const SizedBox(width: 8),
                if (_locked)
                  const PremiumLockPill()
                else if (done)
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.greenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      size: 14,
                      color: AppColors.green,
                    ),
                  )
                else
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: AppColors.inkFaint,
                  ),
              ],
            ),
          ),
        ),
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
