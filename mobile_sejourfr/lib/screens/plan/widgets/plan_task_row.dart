import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../tcf_production/production_nav.dart';
import '../../tcf_production/tcf_production_module.dart';
import '../plan_labels.dart';
import 'plan_tokens.dart';

/// **Une tâche d'expression**, telle que le Plan la voit : son rang, son
/// avancement observé, et le tap qui ouvre ses **compétences** — l'écran
/// existant du parcours (`CompetencesTabView`), jamais une seconde liste.
///
/// Extrait à la **2ᵉ occurrence** : la fiche d'un domaine et la page « Toutes
/// mes compétences » listent les mêmes tâches ; deux copies auraient fini par
/// compter différemment ou par ouvrir deux écrans.
class PlanTaskRow extends StatelessWidget {
  const PlanTaskRow({
    super.key,
    required this.task,
    required this.epreuve,
    required this.first,
  });

  final PlanDomainTask task;
  final EpreuveType epreuve;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final module = epreuve == EpreuveType.tcfEo
        ? TcfProductionModule.eo
        : TcfProductionModule.ee;
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: () => context.push(
          productionCompetencesPath(module, task.tacheNumero),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
          decoration: BoxDecoration(
            border: first
                ? null
                : const Border(top: BorderSide(color: AppColors.lineSoft)),
          ),
          child: Row(
            children: [
              PlanRankBadge(rank: task.tacheNumero, tone: AppColors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planTaskTitle(task),
                      style: AppFonts.ui(size: 14.5, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      planTaskObservedLabel(task),
                      style: AppFonts.ui(
                        size: 12.5,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                task.taskCode,
                style: AppFonts.label(size: 11.5),
              ),
              const SizedBox(width: 8),
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
}
