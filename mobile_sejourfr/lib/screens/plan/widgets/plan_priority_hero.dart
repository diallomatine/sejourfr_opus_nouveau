import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/gradient_hero.dart';
import '../../../core/widgets/premium_lock.dart';
import 'plan_tokens.dart';

/// **La priorité actuelle** : ce que le Plan travaille en ce moment, et le seul
/// bloc qui porte l'appel à l'action principal.
///
/// Le titre, la compétence et l'explication sont **servis** ; le rail des
/// paliers lit le cycle. L'objectif est **nullable** — sans démarche déclarée,
/// la ligne « Objectif » disparaît au lieu d'annoncer un B2 qui n'a été
/// demandé par personne.
class PlanPriorityHero extends StatelessWidget {
  const PlanPriorityHero({
    super.key,
    required this.priority,
    required this.cycle,
    required this.objective,
    required this.ctaLabel,
    required this.onCta,
    required this.onWhy,
    this.onDetail,
    this.ctaLocked = false,
  });

  final LearningPlanPriority? priority;
  final PlanCycle? cycle;
  final TargetLevel? objective;
  final String ctaLabel;
  final VoidCallback? onCta;
  final VoidCallback onWhy;
  final VoidCallback? onDetail;

  /// L'action ouvre l'offre au lieu de l'exercice. Le bloc reste **entier** :
  /// on ne masque ni la priorité, ni l'explication, ni le rail.
  final bool ctaLocked;

  @override
  Widget build(BuildContext context) {
    final current = priority;
    final white = AppColors.white;
    return GradientHero(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.zap,
                size: 14,
                color: white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Text(
                'PRIORITÉ ACTUELLE',
                style: AppFonts.label(
                  size: 11.5,
                  color: white.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              if (ctaLocked) const PremiumLockTag(),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            current?.title ?? 'Votre prochaine priorité se prépare',
            style: AppFonts.display(size: 21, height: 1.15, color: white),
          ),
          if (current != null) ...[
            const SizedBox(height: 9),
            _HeroChip(
              label: current.skillCode.isEmpty
                  ? current.section.label
                  : '${current.skillCode} · ${current.section.label}',
            ),
          ],
          if (current?.explanation != null) ...[
            const SizedBox(height: 11),
            Text(
              current!.explanation!,
              style: AppFonts.ui(
                size: 13.5,
                height: 1.5,
                color: white.withValues(alpha: 0.92),
              ),
            ),
          ],
          if (objective != null) ...[
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.only(top: 13),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: white.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.target, size: 15, color: white),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Objectif ${objective!.wire} — ${objective!.demarcheLabel}',
                      style: AppFonts.ui(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          PlanLevelRail(current: cycle?.targetLevel, onDark: true),
          const SizedBox(height: 16),
          AppButton(
            label: ctaLabel,
            variant: AppButtonVariant.soft,
            icon: ctaLocked ? LucideIcons.lock : LucideIcons.play,
            onPressed: onCta,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroLink(label: 'Voir pourquoi', onTap: onWhy),
              if (onDetail != null) ...[
                const SizedBox(width: 10),
                _HeroLink(
                  label: 'Voir le détail',
                  onTap: onDetail!,
                  dimmed: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: AppFonts.ui(
            size: 12.5,
            weight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      );
}

class _HeroLink extends StatelessWidget {
  const _HeroLink({
    required this.label,
    required this.onTap,
    this.dimmed = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: AppFonts.ui(
            size: 13.5,
            weight: FontWeight.w700,
            color: AppColors.white.withValues(alpha: dimmed ? 0.68 : 1),
          ),
        ),
      );
}
