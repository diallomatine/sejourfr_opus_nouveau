import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/list_group.dart';
import '../plan_labels.dart';

/// **Ce qui a changé récemment.**
///
/// 🛑 Son absence est le cas **normal** : quand rien n'a bougé, le serveur ne
/// sert rien et cette section n'existe pas. Aucune ligne n'est fabriquée pour
/// remplir la place — c'est l'appelant qui décide de ne pas la construire.
///
/// La **fenêtre affichée est celle du serveur** (`window.label`, libellé gelé) :
/// jamais celle que le client croit avoir demandée.
class PlanChangesSection extends StatelessWidget {
  const PlanChangesSection({
    super.key,
    required this.changes,
    required this.onDetail,
  });

  final PlanRecentChanges changes;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final newPriority = changes.newPriority;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: changes.window.label,
          action: TextButton(
            onPressed: onDetail,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              kPlanChangesDetail,
              style: AppFonts.ui(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < changes.transitions.length; i++) ...[
                if (i > 0) const SizedBox(height: 13),
                PlanTransitionLine(transition: changes.transitions[i]),
              ],
              if (newPriority != null) ...[
                if (changes.transitions.isNotEmpty) const SizedBox(height: 13),
                Container(
                  padding: EdgeInsets.only(
                    top: changes.transitions.isEmpty ? 0 : 12,
                  ),
                  decoration: BoxDecoration(
                    border: changes.transitions.isEmpty
                        ? null
                        : const Border(
                            top: BorderSide(color: AppColors.lineSoft),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kPlanChangesNewPriority,
                        style: AppFonts.label(size: 11.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        newPriority.title,
                        style: AppFonts.ui(
                          size: 14.5,
                          weight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        planSkillMeta(
                          newPriority.skillCode,
                          newPriority.section,
                        ),
                        style: AppFonts.ui(
                          size: 12,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Une transition d'état **réellement mesurée**. Le sens (« ça progresse ») est
/// **dérivé serveur** : on ne compare jamais deux paliers à la main, l'ordre
/// des états n'appartient pas au front.
class PlanTransitionLine extends StatelessWidget {
  const PlanTransitionLine({super.key, required this.transition});

  final PlanMasteryTransition transition;

  @override
  Widget build(BuildContext context) {
    final forward = transition.progress;
    final tone = forward ? AppColors.green : AppColors.inkFaint;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            forward ? LucideIcons.arrowUp : LucideIcons.minus,
            size: 13,
            color: tone,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transition.title,
                style: AppFonts.ui(
                  size: 14.5,
                  weight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${planSkillMeta(transition.skillCode, transition.section)} · '
                '${planTransitionLabel(transition)}',
                style: AppFonts.ui(
                  size: 13,
                  height: 1.45,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
