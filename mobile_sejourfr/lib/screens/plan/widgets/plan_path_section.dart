import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/list_group.dart';
import '../plan_labels.dart';

/// **Mon chemin vers l'objectif** : les étapes du cycle, de la première à la
/// dernière, avec celle en cours mise en évidence.
///
/// Le serveur dit **quoi** (compléter le profil, construire un palier, le
/// stabiliser) et **où en est le candidat** ; le titre est d'ici. L'objectif
/// est **nullable** — sans démarche déclarée, le titre de la section ne nomme
/// aucun palier plutôt que d'en inventer un.
class PlanPathSection extends StatelessWidget {
  const PlanPathSection({super.key, required this.cycle});

  final PlanCycle cycle;

  @override
  Widget build(BuildContext context) {
    final steps = cycle.path;
    if (steps.isEmpty) return const SizedBox.shrink();
    final objective = cycle.objectiveLevel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title: planPathTitle(objective)),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < steps.length; i++)
                _PathRow(
                  index: i,
                  step: steps[i],
                  objective: objective,
                  isLast: i == steps.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({
    required this.index,
    required this.step,
    required this.objective,
    required this.isLast,
  });

  final int index;
  final PlanPathStep step;
  final TargetLevel? objective;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final done = step.status == PlanPathStepStatus.done;
    final current = step.status == PlanPathStepStatus.current;
    final Color dotBg;
    final Color dotFg;
    if (current) {
      dotBg = AppColors.blue;
      dotFg = AppColors.white;
    } else if (done) {
      dotBg = AppColors.blueLight;
      dotFg = AppColors.blue;
    } else {
      dotBg = AppColors.surface3;
      dotFg = AppColors.inkFaint;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: dotBg, shape: BoxShape.circle),
                  child: done
                      ? Icon(LucideIcons.check, size: 13, color: dotFg)
                      : Text(
                          '${index + 1}',
                          style: AppFonts.display(size: 12, color: dotFg),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 2),
                      color: done || current
                          ? AppColors.blue.withValues(alpha: 0.35)
                          : AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          planPathStepTitle(step, objective),
                          style: AppFonts.ui(
                            size: 14.5,
                            weight: current ? FontWeight.w700 : FontWeight.w600,
                            height: 1.25,
                            color: done ? AppColors.inkSoft : AppColors.ink,
                          ),
                        ),
                      ),
                      if (current) ...[
                        const SizedBox(width: 8),
                        const AppTag(
                          label: 'EN COURS',
                          tone: TagTone.blue,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    planPathStepStatusLabel(step.status),
                    style: AppFonts.ui(
                      size: 12.5,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
