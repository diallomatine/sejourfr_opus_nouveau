import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/premium_lock.dart';
import 'plan_milestone_labels.dart';
import 'plan_milestone_launcher.dart';

/// Le **jalon** du Plan : un examen blanc que le serveur juge mérité.
///
/// ⚠️ **Rien n'est décidé ici.** Quelle épreuve, quel slot, verrouillé ou non :
/// tout vient de `LearningPlan.milestone` (`PlanMilestoneSelector` côté
/// serveur). L'app n'apporte que la **phrase** — le serveur expose des faits —
/// et le **chemin de démarrage**, qui vit dans `startPlanMilestone` depuis que
/// la séance du jour lance le même examen depuis une ligne de liste.
///
/// **Verrouillé, le jalon reste entier** : titre, motif, épreuve, slot et durée
/// s'affichent à l'identique, seul le bouton change de destination — le Plan
/// reste intégralement visible, seuls les accès sont fermés.
class PlanMilestoneCard extends ConsumerStatefulWidget {
  const PlanMilestoneCard({super.key, required this.milestone});

  final PlanMilestone milestone;

  @override
  ConsumerState<PlanMilestoneCard> createState() => _PlanMilestoneCardState();
}

class _PlanMilestoneCardState extends ConsumerState<PlanMilestoneCard> {
  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    await startPlanMilestone(context, ref, widget.milestone);
    if (mounted) setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    final milestone = widget.milestone;
    final locked = milestone.locked;
    return AppCard(
      border: Border.all(color: AppColors.green.withValues(alpha: 0.24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppTag(
                label: kPlanMilestonePill,
                tone: TagTone.success,
                icon: LucideIcons.flag,
                compact: true,
              ),
              const Spacer(),
              if (locked) ...[
                const PremiumLockTag(),
                const SizedBox(width: 6),
              ],
              AppTag(
                label: '≈ ${milestone.estimatedMinutes} min',
                tone: TagTone.neutral,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(milestone.displayTitle, style: AppFonts.display(size: 20)),
          const SizedBox(height: 7),
          Text(
            milestone.displayText,
            style: AppFonts.ui(
              size: 12.5,
              height: 1.45,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 15),
          _MilestoneRow(milestone: milestone),
          const SizedBox(height: 13),
          if (locked) ...[
            AppButton(
              label: kPlanMilestoneLockedCta,
              icon: LucideIcons.lock,
              variant: AppButtonVariant.soft,
              onPressed: () => unawaited(showTcfLockPaywall(context)),
            ),
            const SizedBox(height: 9),
            Text(
              kPlanMilestoneLockNote,
              style: AppFonts.ui(
                size: 11.5,
                height: 1.4,
                color: AppColors.inkFaint,
              ),
            ),
          ] else
            Semantics(
              label: '$kPlanMilestoneCta : ${milestone.displayTitle}',
              button: true,
              child: AppButton(
                label: kPlanMilestoneCta,
                iconRight: LucideIcons.arrowRight,
                isLoading: _starting,
                onPressed: _starting ? null : () => unawaited(_start()),
              ),
            ),
        ],
      ),
    );
  }
}

/// Le repère factuel du jalon — quel examen de la grille, quelle durée —,
/// annoncé **à l'identique qu'il soit verrouillé ou non**, comme la ligne
/// d'exercice recommandé d'une étape.
class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone});

  final PlanMilestone milestone;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                milestone.isFullExam
                    ? LucideIcons.trophy
                    : milestone.epreuve == EpreuveType.tcfEo
                        ? LucideIcons.mic
                        : LucideIcons.penLine,
                size: 18,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.ui(size: 13.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    milestone.displayMeta,
                    style: AppFonts.ui(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
